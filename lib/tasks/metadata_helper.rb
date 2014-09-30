module MetadataHelper
  require 'mongoid'
  require 'rspotify'
  require 'lastfm'

  MINIMUM_TAG_VOTE_THRESHOLD = 5

  @@lastfm = Lastfm.new(ENV['last_fm_key'], ENV['last_fm_secret'])

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
    artist_matches = RSpotify::Artist.search("#{review.artist}")

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
        if Text::Levenshtein.distance(album.name.downcase, review.album_title.downcase) < 8
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
        album_matches = RSpotify::Album.search("#{review.album_title}")

        album_matches.each_with_index do |album, index|
          break if index == MAX_ALBUM_CHECKS
          if Text::Levenshtein.distance(album.artists[0].name, review.artist) < 5
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
      Rails.logger.info "Setting Spotify metadata for '#{review.artist} - #{review.album_title}'"
      review.spotify_artist_id = artist_id
      review.spotify_album_id = album_id
      review.spotify_artist_popularity = artist_popularity
      review.spotify_album_popularity = album_popularity
      review.spotify_track_ids = track_ids
      review.spotify_genres = genres
      review.spotify_release_date = Date.parse(release_date) if release_date and release_date.to_s.strip.length > 4
    else
      Rails.logger.info "Couldn't find spotify Metadata for '#{review.artist} - #{review.album_title}'"
    end
  end
end

