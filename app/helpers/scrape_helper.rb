module ScrapeHelper
  require 'mongoid'
  require 'nokogiri'
  require 'open-uri'
  require 'rspotify'
  require 'common_utils'

  include CommonUtils

  # Length of wait between album review page scrapes.
  SLEEP_SECONDS = 7

  # Don't iterate through more than this many artists matches when searching for matching album.
  MAX_ARTIST_CHECKS = 5

  # Don't iterate through more than this many album matches when searching for matching album.
  MAX_ALBUM_CHECKS = 5

  # Number of retries on a URL.
  MAX_RETRY_ATTEMPTS = 10 

  SCORE_SELECTOR = 'span.score'
  ARTIST_SELECTOR = 'h1'
  ALBUM_TITLE_SELECTOR = 'h2'
  ALBUM_IMAGE_SELECTOR = 'div.artwork > img'

  # Downloads each album review on the specified pages and stores them in the database.
  #
  # This method is idempotent - if a document with the given url already exists, it is updated.
  # @param page_min   Page to start on.
  # @param page_max   Last page to try.
  def slurp_album_reviews(page_min=1, page_max=800)
    for i in page_min..page_max
      root_url = "#{Rails.configuration.album_listing_url}/#{i}"
      Rails.logger.info "Scraping albums listing page '#{root_url}'"

      listing_document = get_document root_url

      # Iterate over each link to an album review, download the review's html, save it.
      listing_document.css('.object-grid a').each  do |review_a|
        album_href = review_a.attr('href') 
        album_url = "#{Rails.configuration.pitchfork_root_url}#{album_href}"

        Rails.logger.info "Scraping album review page '#{album_url}'"
        album_document = get_document album_url
        album_html = album_document.css('#main').first.to_html

        # Find or save the review.
        review_page = Review.where(:url => album_url).first_or_create.update_attribute(:html, album_html)
        sleep(SLEEP_SECONDS.seconds)
      end  
    end
  end

  # Gets a Nokogiri document for the given url.
  #
  # @param url URL to generate a document from.
  def get_document(url)
    attempts = 1

    begin
      document = Nokogiri::HTML(open(url).read)
    rescue Exception => ex
      Rails.logger.error "Error when extracting #{url}: #{ex}"

      if (attempts < MAX_RETRY_ATTEMPTS)
        Rails.logger.info "Retrying."
        attempts += 1
        retry
      else
        raise "Maximum number of retries on #{url}"
      end

    end

    document
  end

  # Gets score from review object.
  #
  # @param review   Review from which the score should be extracted.
  def enrich_review_with_score(review)
    review.score = get_text_from_review(review, SCORE_SELECTOR).to_f
    Rails.logger.info "Setting score for '#{review.url}' as '#{review.score}'"
  end

  # Gets artist from review object.
  #
  # @param review   Review from which the artist should be extracted.
  def enrich_review_with_artist(review)
    review.artist = get_text_from_review(review, ARTIST_SELECTOR)
    Rails.logger.info "Setting artist for '#{review.url}' as '#{review.artist}'"
  end

  # Gets album title from review object.
  #
  # @param review   Review from which the album title should be extracted.
  def enrich_review_with_album_title(review)
    review.album_title = get_text_from_review(review, ALBUM_TITLE_SELECTOR)
    Rails.logger.info "Setting album title for '#{review.url}' as '#{review.album_title}'"
  end

  # Downloads album image from review object.
  #
  # @param review   Review from which the album image should be extracted.
  def enrich_review_with_image(review)
    image_path = get_img_from_review(review, ALBUM_IMAGE_SELECTOR)
    review.album_image = image_path
    Rails.logger.info "Setting album image for '#{review.url}' as '#{image_path}'"
  end

  # Gets Spotify metadata for review object.
  #
  # @param review   Review to enrich with Spotify metadata.
  def enrich_review_with_spotify_metadata(review)
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
        if Text::Levenshtein.distance(album.name, review.album_title) < 5
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

  # Extracts text from review using a CSS selector.
  #
  # @param review   Review from which the text should be extracted.
  # @param selector CSS selector. First match is returned as a string.
  def get_text_from_review(review, selector)
    doc = Nokogiri::HTML(review.html)
    text = doc.css(selector)

    if text.blank? || text.first.blank? || text.first.content.blank?
      Rails.logger.warn "No match found for selector #{selector}." 
      return nil
    end

    text.first.content.strip
  end

  # Extracts image link value from review using a CSS selector.
  #
  # @param review   Review from which the image link should be extracted.
  # @param selector CSS selector. img src value of first match is returned as a string.
  def get_img_from_review(review, selector)
    doc = Nokogiri::HTML(review.html)
    images = doc.css(selector)

    if images.blank? || images.first.blank? || images.first['src'].blank?
      Rails.logger.warn "No img match found for selector #{selector}."
      return nil
    end

    image_name = generate_album_image_name(review.artist, review.album_title)
    Rails.logger.warn "Downloading image #{images.first['src']}"
    extension = File.extname(images.first['src'])
    open("#{Rails.root}/app/assets/images/album_art/#{image_name}#{extension}", 'wb') do |file|
      file << open(images.first['src']).read
    end

    "#{image_name}#{extension}"
  end

end
