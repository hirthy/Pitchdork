module Api::V1
  class ReviewsController < ApiController
    include CommonUtils, SearchHelper

    # GET /v1/reviews
    def index
      if params[:artist]
        @results = Review.without(:_id, :url, :html, :body, :reviewer_name, :album_image, :spotify_artist_id, :spotify_artist_popularity, :spotify_album_popularity, :spotify_album_id, :spotify_release_date, :spotify_track_ids, :spotify_genres, :spotify_last_check, :last_fm_tags, :album_image_path).where(:publish_date.exists => true, :genre.exists => true, :artist => params[:artist]).entries.map {|d| d.as_document}
      else
        @results = Review.without(:_id, :url, :html, :body, :reviewer_name, :album_image, :spotify_artist_id, :spotify_artist_popularity, :spotify_album_popularity, :spotify_album_id, :spotify_release_date, :spotify_track_ids, :spotify_genres, :spotify_last_check, :last_fm_tags, :album_image_path).where(:publish_date.exists => true, :genre.exists => true).entries.map {|d| d.as_document}
      end

      render json: @results
    end
  end
end