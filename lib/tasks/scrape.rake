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

  task :find_scores => :environment do |t, args|
    Rails.logger.info "Finding the scores for all Reviews."

    Review.all.each do |review|
      enrich_review_with_score review
      review.save
    end

    Rails.logger.info "Done"
  end

  task :find_artists => :environment do |t, args|
    Rails.logger.info "Finding the artists for all Reviews."

    Review.all.each do |review|
      enrich_review_with_artist review
      review.save
    end

    Rails.logger.info "Done"
  end

  task :find_body => :environment do |t, args|
    Rails.logger.info "Finding the body for all Reviews."

    Review.all.each do |review|
      enrich_review_with_body review
      review.save
    end

    Rails.logger.info "Done"
  end

  task :find_reviewers => :environment do |t, args|
    Rails.logger.info "Finding the reviewers for all Reviews."

    Review.all.each do |review|
      enrich_review_with_reviewer_name review
      review.save
    end

    Rails.logger.info "Done"
  end

  task :find_album_titles => :environment do |t, args|
    Rails.logger.info "Finding the album titles for all Reviews."

    Review.all.each do |review|
      enrich_review_with_album_title review
      review.save
    end

    Rails.logger.info "Done"
  end

  task :find_album_images => :environment do |t, args|
    Review.all.each do |review|
      enrich_review_with_image review
      review.save
    end
  end

end
