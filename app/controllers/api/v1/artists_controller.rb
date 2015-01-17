module Api::V1
  class ArtistsController < ApiController
    include CommonUtils, SearchHelper

    @@client = Elasticsearch::Client.new url: ENV['BONSAI_URL']

    # GET /v1/reviews
    def index
      params = request.query_parameters
      query_string = '*:*'
      query_string = params['q'] if !params['q'].nil? and !params['q'].empty? and !(params['q'].strip || params['q']).empty?
      filters = if params.has_key?('filter') then JSON.parse(params['filter']) else {} end

      query = generate_query(query_string, filters)

      result = @@client.search index: 'artist', body: query

      tags = []
      reviewers = []
      hits = if result['hits'].has_key? 'hits' then result['hits']['hits'] else [] end

      results = []
      hits.each do |hit|
        result = hit['_source']
        results.append(result)
      end
      puts results
      render json: {hits: results, facets: {Tags: tags, Reviewers: reviewers}}
    end
  end
end