class Review
  include Mongoid::Document

  field :url, type: String
  field :html, type: String
  field :artist, type: String
  field :album_title, type: String
  field :album_image, type: String
  field :score, type: Float

  # Spotify Metadata
  field :spotify_artist_id, type: String
  field :spotify_artist_popularity, type: Integer
  field :spotify_album_popularity, type: Integer
  field :spotify_album_id, type: String
  field :spotify_release_date, type: Date
  field :spotify_track_ids, type: Array
  field :spotify_genres, type: Array

  attr_reader :album_image_path

  validates_uniqueness_of :url
  validates_presence_of :url, :html

  # Scopes
  scope :spotify_metadata_added, where(:url.exists => true)

  def album_image_path()
    ActionController::Base.helpers.image_path(self.album_image)
  end
end
