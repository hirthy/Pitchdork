require "#{Rails.root}/app/helpers/scrape_helper"
require "pry"
include ScrapeHelper

namespace :scrape do
  desc "Downloads all album reviews on Pitchforkmedia.com and saves them to the database."

  task :slurp_reviews, [:min_page, :max_page] => :environment do |t, args|
    Rails.logger.info "Slurping album reviews between pages #{args.min_page} and #{args.max_page}"
    slurp_album_reviews args.min_page, args.max_page
    Rails.logger.info "Done"
  end

end
