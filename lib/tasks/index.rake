require "#{Rails.root}/lib/tasks/index_helper"
include IndexHelper

namespace :index do

  task :create_new_index => :environment do |t, args|
    create_index()
  end

end