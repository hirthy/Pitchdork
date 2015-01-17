module Api::V1
  class ReviewsController < ApiController
    include CommonUtils, SearchHelper

    # GET /v1/reviews
    def index
      if params[:artist]
        @results = Review.only(:artist, :score, :album_title, :genre, :publish_date).where(:publish_date.exists => true, :genre.exists => true, :artist => params[:artist])
      else
        @results = Review.only(:artist, :score, :album_title, :genre, :publish_date).where(:publish_date.exists => true, :genre.exists => true)
      end

      render json: @results
    end
  end
end