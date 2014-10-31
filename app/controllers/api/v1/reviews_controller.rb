module Api::V1
  class ReviewsController < ApiController
    include CommonUtils

    @@client = Elasticsearch::Client.new url: ENV['es_url']

    # GET /v1/reviews
    def index
      params = request.query_parameters
      query = '*:*'
      query = params['q'] if !params['q'].nil? and !params['q'].empty? and !(params['q'].strip || params['q']).empty?
      filters = params['filters'] if params.has_key?('filters')

      body = {
          query: {
              query_string: {
                  fields: ['body', 'artist^4', 'album_title^4'],
                  query: query
              }
          },
          facets: {
              last_fm_tags: {
                  terms: {
                      field: 'last_fm_tags',
                      size: 500
                  }
              }
          }
      }

      # if !filters.nil? and filters.length > 0
      #   for
      #   body[:filter] = {
      #
      #   }
      # end

      result = @@client.search index: 'reviews', body: body



      hits = result['hits']['hits'] if result['hits'].has_key? 'hits' else []
      tags = result['facets']['last_fm_tags']['terms']

      results = []
      hits.each do |hit|
        result = hit['_source']
        image_path = '/assets/album_art/' + generate_album_image_name(result['artist'], result['album_title'])
        image_path = ActionController::Base.helpers.asset_path(image_path)
        result['image_path'] = image_path
        results.append(result)
      end

      render json: {hits: results, facets: {Tags: tags}}
    end

  end
end