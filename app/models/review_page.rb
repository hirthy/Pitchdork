class ReviewPage
  include Mongoid::Document

  field :url, type: String
  field :html, type: String

  validates_uniqueness_of :url
  validates_presence_of :url, :html
end
