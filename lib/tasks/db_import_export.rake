namespace :db do
  def collections
  [
    { model: "Review", table: "reviews" }
  ]
  end
  task :export => :environment do
    collections.each do |collection|
      table = collection[:table]
      model = collection[:model]
      dir = "db/seed/" + Rails.env
      #filename = dir + "/" + table + ".json"
      filename = "public/" + table + ".json"
      Dir.mkdir dir unless (Dir.exists? dir)
      model = model.constantize
      objects = model.where(:publish_date.exists => true, :artist.exists => true, :album_title.exists => true, :genre.exists => true).order_by(:publish_date => 'asc')
      reviews = Array.new
      File.open(File.join(Rails.root, filename), "w") do |f|
        f.write(objects.to_json);
      end
    end
  end
end