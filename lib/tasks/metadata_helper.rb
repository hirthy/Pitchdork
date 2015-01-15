module MetadataHelper
  require 'mongoid'
  require 'rspotify'
  require 'lastfm'

  MINIMUM_TAG_VOTE_THRESHOLD = 5

  @@lastfm = Lastfm.new(ENV['last_fm_key'], ENV['last_fm_secret'])

  def add_echonest_metadata(review)
    if !review.artist || (review.artist.downcase.include? 'various artists')
      return nil
    end
    
    if review.artist.nil?
      Rails.logger.error("Review with URL #{review.url} has no artist property set.")
      return review
    end

    artist_name = review.artist.gsub(/\//, '').downcase

    artist = Echonest::Artist.new(ENV['echonest_key'])
    params = { name: artist_name  }
    max_tries = 5
    begin
      artist_search = artist.search(params)
    rescue Echonest::Error => e
      Rails.logger.info "Something happened with echonest, error: #{e}"
      if max_tries > 0
        max_tries -= 1
        sleep(60)
        retry
      end
      Rails.logger.info "Giving up on finding artist for #{artist_name}"
    else
      if artist_search.length > 0
        first_artist = artist_search[0]
        begin
          artist_terms = first_artist.terms #this is another API hit
        rescue Echonest::Error => e
          Rails.logger.info "Something happened with echonest, error: #{e}"
          if max_tries > 0
            max_tries -= 1
            sleep(60)
            retry
          end
          Rails.logger.info "Giving up on finding terms for #{artist_name}"
        else
          if artist_terms.length > 0
            genre = artist_terms[0][:name]
            review.genre = genre
            Rails.logger.info "Setting Echonest genre for #{artist_name} - #{genre}"
          else 
            Rails.logger.info "No terms found for #{artist_name}"
            return nil
          end
        end
      else
        Rails.logger.info "No artists found for #{artist_name}"
        return nil
      end
    end
  end


  def add_last_fm_metadata(review)
    if !review.artist || (review.artist.downcase.include? 'various artists')
      return nil
    end

    begin
      tags = @@lastfm.artist.get_top_tags(:artist => review.artist)
    rescue
      Rails.logger.warn "Exception finding tags for #{review.artist}"
    end

    tags = tags.find_all{|t| t['count'].to_i > MINIMUM_TAG_VOTE_THRESHOLD} if !tags.nil?
    tags = tags.map {|t| t['name']} if !tags.nil?
    review.last_fm_tags = tags
    Rails.logger.info "#{review.artist} tags: '#{review.last_fm_tags}''"
  end

  def get_validation_url
    token = @@lastfm.auth.get_token
    Rails.logger.info "Authorize at http://www.last.fm/api/auth/?api_key=#{ENV['last_fm_key']}&token=#{token}"
  end

  # Gets Spotify metadata for review object.
  #
  # @param review   Review to enrich with Spotify metadata.
  def add_spotify_metadata(review)
    if review.artist.nil?
      Rails.logger.error("Review with URL #{review.url} has no artist property set.")
      return review
    end

    artist_name = review.artist.gsub(/\//, '').downcase

    if review.album_title != 'EP'
      album_title = review.album_title.gsub(/\bEP\b/, '').downcase
    else
      album_title = review.album_title.downcase
    end

    artist_matches = RSpotify::Artist.search(artist_name)

    artist_id = nil
    artist_popularity = nil
    album_popularity = nil
    album_id = nil
    genres = []
    release_date = nil
    track_ids = []

    artist_matches.each_with_index do |artist, index|
      break if index == MAX_ARTIST_CHECKS

      # First try by artist.
      artist.albums.each do |album|
        if Text::WhiteSimilarity.similarity(album.name.downcase, album_title) > 0.65
          artist_id = artist.id
          album_id = album.id
          artist_popularity = artist.popularity
          album_popularity = album.popularity
          release_date = album.release_date
          genres = album.genres
          track_ids = album.tracks.map {|t| t.id }.compact
          break
        end
      end

      # Try album endpoint if no match by artist.
      if not album_id
        album_matches = RSpotify::Album.search(album_title)

        album_matches.each_with_index do |album, index|
          break if index == MAX_ALBUM_CHECKS
          if Text::WhiteSimilarity.similarity(album.artists[0].name, artist_name) > 0.65
            artist_id = artist.id
            album_id = album.id
            artist_popularity = artist.popularity
            album_popularity = album.popularity
            release_date = album.release_date
            genres = album.genres
            track_ids = album.tracks.map {|t| t.id }.compact
            break
          end
        end
      end
    end

    if artist_id
      Rails.logger.info "Setting Spotify metadata for '#{artist_name} - #{album_title}'"
      review.spotify_artist_id = artist_id
      review.spotify_album_id = album_id
      review.spotify_artist_popularity = artist_popularity
      review.spotify_album_popularity = album_popularity
      review.spotify_track_ids = track_ids
      review.spotify_genres = genres

      begin
        review.spotify_release_date = Date.parse(release_date) if release_date and release_date.to_s.strip.length > 4
      rescue Exception
        Rails.logger.info "Couldn't parse date #{release_date}"
      end
    else
      Rails.logger.info "Couldn't find spotify Metadata for '#{review.artist} - #{review.album_title}'"
    end

    review.spotify_last_check = DateTime.now
  end

end

