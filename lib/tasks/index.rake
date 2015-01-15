require "#{Rails.root}/lib/tasks/index_helper"
include IndexHelper

namespace :index do

  desc "Create Elasticsearch index, add all reviews."
  task :create_index => :environment do |t, args|
    create_index()
  end

  desc "Create Elasticsearch index, add all artists."
  task :create_artist_index => :environment do |t, args|
    create_artist_index()
  end

end