module Api::V1
  class ReviewsController < ApiController
    include CommonUtils, SearchHelper

    @@client = Elasticsearch::Client.new url: ENV['es_url']

    # GET /v1/reviews
    def index
      params = request.query_parameters
      query_string = '*:*'
      query_string = params['q'] if !params['q'].nil? and !params['q'].empty? and !(params['q'].strip || params['q']).empty?
      filters = if params.has_key?('filter') then JSON.parse(params['filter']) else {} end

      query = generate_query(query_string, filters)
      result = @@client.search index: 'reviews', body: query


      tags = []
      reviewers = []
      hits = if result['hits'].has_key? 'hits' then result['hits']['hits'] else [] end

      if hits.length > 1
        reviewers = result['facets']['reviewer_name']['terms']
        tags = result['facets']['last_fm_tags']['terms']
      end

      results = []
      hits.each do |hit|
        result = hit['_source']
        image_path = '/assets/album_art/' + generate_album_image_name(result['artist'], result['album_title'])
        image_path = ActionController::Base.helpers.asset_path(image_path)
        result['image_path'] = image_path
        results.append(result)
      end

      render json: {hits: results, facets: {Tags: tags, Reviewers: reviewers}}
    end
  end
end