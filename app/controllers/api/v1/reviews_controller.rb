module Api::V1
  class ReviewsController < ApiController
    include CommonUtils

    @@client = Elasticsearch::Client.new url: ENV['es_url']

    # GET /v1/reviews
    def index
      params = request.query_parameters
      result = @@client.search index: 'reviews', body: {
          query: {
              query_string: {
                  fields: ['body', 'artist^4', 'album_title^4'],
                  query: params['q']
              }
          }
      }

      hits = result['hits']['hits'] if result['hits'].has_key? 'hits' else []
      results = []
      hits.each do |hit|
        result = hit['_source']
        image_path = '/assets/album_art/' + generate_album_image_name(result['artist'], result['album_title'])
        image_path = ActionController::Base.helpers.asset_path(image_path)
        result['image_path'] = image_path
        results.append(result)
      end

      render json: results
    end

  end
end