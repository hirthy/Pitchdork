require "#{Rails.root}/lib/tasks/scrape_helper"
require "text"
include ScrapeHelper

namespace :scrape do
  desc "Downloads all album reviews on Pitchforkmedia.com and saves them to the database."
  task :slurp_reviews, [:min_page, :max_page] => :environment do |t, args|
    Rails.logger.info "Slurping album reviews between pages #{args.min_page} and #{args.max_page}"
    slurp_album_reviews args.min_page, args.max_page
    Rails.logger.info "Done"
  end

  desc "Run all extraction tasks."
  task :extract_all => :environment do
    Review.all.each do |review|
      enrich_review_with_score review
      enrich_review_with_artist review
      enrich_review_with_body review
      enrich_review_with_publish_date review
      enrich_review_with_reviewer_name review
      enrich_review_with_album_title review
      enrich_review_with_image review
      review.save
    end
  end

  desc "Extracts scores."
  task :find_scores => :environment do |t, args|
    Rails.logger.info "Finding the scores for all Reviews."

    Review.all.each do |review|
      enrich_review_with_score review
      review.save
    end

    Rails.logger.info "Done"
  end

  desc "Extracts artists."
  task :find_artists => :environment do |t, args|
    Rails.logger.info "Finding the artists for all Reviews."

    Review.all.each do |review|
      enrich_review_with_artist review
      review.save
    end

    Rails.logger.info "Done"
  end

  desc "Extracts body."
  task :find_body => :environment do |t, args|
    Rails.logger.info "Finding the body for all Reviews."

    Review.all.each do |review|
      enrich_review_with_body review
      review.save
    end

    Rails.logger.info "Done"
  end

  desc "Extracts publish date."
  task :find_publish_date => :environment do |t, args|
    Rails.logger.info "Finding the publish date for all Reviews."

    Review.all.each do |review|
      enrich_review_with_publish_date review
      review.save
    end

    Rails.logger.info "Done"
  end

  desc "Extracts reviewers."
  task :find_reviewers => :environment do |t, args|
    Rails.logger.info "Finding the reviewers for all Reviews."

    Review.all.each do |review|
      enrich_review_with_reviewer_name review
      review.save
    end

    Rails.logger.info "Done"
  end

  desc "Extracts album titles."
  task :find_album_titles => :environment do |t, args|
    Rails.logger.info "Finding the album titles for all Reviews."

    Review.all.each do |review|
      enrich_review_with_album_title review
      review.save
    end

    Rails.logger.info "Done"
  end

  desc "Downloads album images."
  task :find_album_images => :environment do |t, args|
    Review.all.each do |review|
      enrich_review_with_image review
      review.save
    end
  end

end
