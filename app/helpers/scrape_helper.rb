module ScrapeHelper
  require 'mongoid'
  require 'nokogiri'
  require 'open-uri'

  # How long we sleep between album review page scrapes.
  SLEEP_SECONDS = 7

  # How many times we retry a url before giving up.
  MAX_RETRY_ATTEMPTS = 10 

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

        # Save to the database.
        update_or_create_document(album_url, album_html)

        sleep(SLEEP_SECONDS.seconds)
      end  
    end
  end

  # Updates or creates a document with url attribute 'url'.
  #
  # @param url  url property of the document.
  # @param html html property value of the document.
  def update_or_create_document(url, html)
    existing_page = ReviewPage.where(:url => url).first
    review_page = existing_page.nil? ? ReviewPage.new : existing_page

    review_page.url = url
    review_page.html = html
    review_page.save
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
        retry
      else
        raise "Maximum number of retries on #{url}"
      end

      attempts += 1
    end

    document
  end
end
