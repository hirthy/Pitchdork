class Review
  include Mongoid::Document

  field :url, type: String
  field :html, type: String
  field :body, type: String
  field :artist, type: String
  field :reviewer_name, type: String
  field :album_title, type: String
  field :album_image, type: String
  field :score, type: Float
  field :publish_date, type: Date

  # Spotify Metadata
  field :spotify_artist_id, type: String
  field :spotify_artist_popularity, type: Integer
  field :spotify_album_popularity, type: Integer
  field :spotify_album_id, type: String
  field :spotify_release_date, type: Date
  field :spotify_track_ids, type: Array
  field :spotify_genres, type: Array
  field :spotify_last_check, :type => DateTime

  # Last.fm Metadata
  field :last_fm_tags, type: Array

  # Echonest Metadata
  field :genre, type: String

  attr_reader :album_image_path

  validates_uniqueness_of :url
  validates_presence_of :url, :html

  # Scopes
  scope :spotify_metadata_added, where(:spotify_album_id.exists => true)
  scope :spotify_metadata_missing, where(:spotify_album_id.exists => false, :spotify_last_check.exists => false)
  scope :last_fm_tags_missing, where(:last_fm_tags.exists => false)
  scope :genre_missing, where(:genre.exists => false)

  index({ publish_date: 1 },{ name: "publish_date_index"})

  def album_image_path()
    ActionController::Base.helpers.image_path(self.album_image)
  end
end
