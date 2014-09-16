module Api::V1
  class ReviewsController < ApiController

    # GET /v1/reviews
    def index
      render json: Review.spotify_metadata_added.limit(5),  methods: [:album_image_path]
    end

  end
end