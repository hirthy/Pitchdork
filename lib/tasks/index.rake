require "#{Rails.root}/lib/tasks/index_helper"
include IndexHelper

namespace :index do

  desc "Create Elasticsearch index, add all reviews."
  task :create_new_index => :environment do |t, args|
    create_index()
  end

end