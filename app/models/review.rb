class Review
  include Mongoid::Document

  field :url, type: String
  field :html, type: String
  field :artist, type: String
  field :album_title, type: String
  field :score, type: Float

  validates_uniqueness_of :url
  validates_presence_of :url, :html
end
