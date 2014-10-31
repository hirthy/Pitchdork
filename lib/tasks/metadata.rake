require "#{Rails.root}/lib/tasks/metadata_helper"
require 'mongoid'
include MetadataHelper

namespace :metadata do

  task :authorize_lastfm => :environment do |t, args|
    get_validation_url
  end

  task :add_last_fm_metadata => :environment do |t, args|
    Review.all.no_timeout.each do |review|
      add_last_fm_metadata review
      review.save
      sleep(0.1)
    end
  end

  task :add_spotify_metadata => :environment do |t, args|
    success_count = 0
    fail_count = 0

    if args.has_key?('all') and args.all
      reviews = Review.all
      Rails.logger.info "Getting all reviews."
    else
      Rails.logger.info "Getting reviews with missing Spotify metadata."
      reviews = Review.spotify_metadata_missing
    end

    # review = Review.where(album_title: "Let Us Never Speak of It Again").first
    # add_spotify_metadata(review)

    reviews.no_timeout.each do |review|
      add_spotify_metadata review

      if review.spotify_album_id
        success_count += 1
      else
        fail_count += 1
      end

      review.save

      sleep(0.5)
    end

    Rails.logger.info "Found Spotify Metadata for #{success_count} reviews, failed for #{fail_count}."
    Rails.logger.info "Done."
  end
end
