module SearchHelper
  class SearchUtil
    @@facet_map = {tags: 'last_fm_tags', reviewers: 'reviewer_name'}

    def get_filters(filters)
      term_filters = []
      result = nil

      filters.each do |key, values|
        result = {}
        es_filter_field = @@facet_map.fetch(key.downcase.to_sym, key.downcase)
        result[es_filter_field] = values
        result[:execution] = 'and'
        term_filters << {terms: result}
      end

      if term_filters.any?
        bool_filter = {
          must: term_filters
        }

        result =  {bool: bool_filter}
      end

      result
    end
  end

  def generate_query(query_string, filters)
    util = SearchUtil.new

    query = {
        filtered: {
            query: {
                query_string: {
                    query: query_string,
                    fields: ['body', 'artist^4', 'album_title^4']
                }
            },
            filter: {}
        }
    }

    body = {
        facets: {
            last_fm_tags: {
                terms: {
                    field: 'last_fm_tags',
                    size: 500
                }
            },
            reviewer_name: {
                terms: {
                    field: 'reviewer_name',
                    size: 500
                }
            },
        }
    }

    filters = util.get_filters(filters)
    query[:filtered][:filter] = filters unless filters.nil?
    body[:query] = query
    body
  end
end
