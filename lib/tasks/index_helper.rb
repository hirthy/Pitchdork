module IndexHelper
  require 'elasticsearch'

  @@client = Elasticsearch::Client.new url: ENV['es_url']

  def create_index
    index_name = "#{ENV['es_index']}-#{Time.now.to_i.to_s}"

    @@client.indices.create :index => index_name,
                            body: {
                                settings: {
                                    index: { number_of_replicas: 0},
                                    analysis: {
                                        analyzer: {
                                            just_lowercase: {
                                                type: 'custom',
                                                filter: ['lowercase'],
                                                tokenizer: 'keyword'
                                            },
                                            shingled: {
                                                type: 'custom',
                                                filter: ['standard', 'lowercase', 'filter_shingle'],
                                                tokenizer: 'standard'
                                            },
                                            html_analyzer: {
                                                type: 'custom',
                                                tokenizer: 'standard',
                                                filter: ['standard', 'lowercase', 'stop', 'snowball'],
                                                char_filter: ['html_strip']
                                            },
                                            uax_url_email: {
                                                type: 'custom',
                                                tokenizer: 'uax_url_email'
                                            }
                                        },
                                        filter: {
                                            filter_shingle: {
                                                type: 'shingle',
                                                max_shingle_size: 3,
                                                min_shingle_size: 2,
                                                output_unigrams: 'false',
                                            }
                                        }
                                    }
                                },
                                mappings: {
                                    review: {
                                        properties: {
                                            url: {type: 'string', analyzer: 'uax_url_email', store: 'true'},
                                            html: {type: 'string', analyzer: 'html_analyzer', store: 'true'},
                                            artist: {type: 'string', analyzer: 'standard', store: 'true'},
                                            body: {type: 'multi_field', fields: {
                                                body: {type: 'string', analyzer: 'standard', store: 'true'},
                                                shingled: {type: 'string', analyzer: 'shingled', store: 'true'}
                                            }},
                                            reviewer_name: {type: 'string', analyzer: 'just_lowercase', store: 'true'},
                                            album_title: {type: 'string', analyzer: 'just_lowercase', store: 'true'},
                                            score: {type: 'integer', store: 'true'},
                                            publish_date: {type: 'date', store: 'true'},
                                            spotify_artist_id: {type: 'string', index: 'not_analyzed', store: 'true'},
                                            spotify_artist_popularity: {type: 'integer', store: 'true'},
                                            spotify_album_popularity: {type: 'integer', store: 'true'},
                                            spotify_album_id: {type: 'string', store: 'true', index: 'not_analyzed'},
                                            spotify_release_date: {type: 'date', store: 'true'},
                                            spotify_track_ids: {type: 'string', store: 'true', index: 'not_analyzed'},
                                            spotify_genres: {store: 'true', type: 'string', analyzer: 'just_lowercase'},
                                            last_fm_tags: {store: 'true', type: 'string', analyzer: 'just_lowercase'}
                                        }
                                    }
                                }
                            }

    Review.all.no_timeout.each do |review|
      id = review['_id'].to_s
      Rails.logger.info("Adding #{review.artist} - #{review.album_title}")
      review = review.as_json
      review['image_path']
      review = review.as_json
      @@client.index index: index_name, type: 'review', id: id, body: review.as_json
    end
  end

  def create_artist_index
    index_name = "artist"

    @@client.indices.create :index => index_name,
                            body: {
                                settings: {
                                    index: { number_of_replicas: 0},
                                    analysis: {
                                        analyzer: {
                                            just_lowercase: {
                                                type: 'custom',
                                                filter: ['lowercase'],
                                                tokenizer: 'keyword'
                                            },
                                            shingled: {
                                                type: 'custom',
                                                filter: ['standard', 'lowercase', 'filter_shingle'],
                                                tokenizer: 'standard'
                                            },
                                            html_analyzer: {
                                                type: 'custom',
                                                tokenizer: 'standard',
                                                filter: ['standard', 'lowercase', 'stop', 'snowball'],
                                                char_filter: ['html_strip']
                                            },
                                            uax_url_email: {
                                                type: 'custom',
                                                tokenizer: 'uax_url_email'
                                            }
                                        },
                                        filter: {
                                            filter_shingle: {
                                                type: 'shingle',
                                                max_shingle_size: 3,
                                                min_shingle_size: 2,
                                                output_unigrams: 'false',
                                            }
                                        }
                                    }
                                },
                                mappings: {
                                    artist: {
                                        properties: {
                                            artist: {type: 'string', analyzer: 'standard', store: 'true'}
                                        }
                                    }
                                }
                            }

    Review.distinct(:artist).each_with_index do |artist,i|
      id = i.to_s
      Rails.logger.info("Adding #{artist}")
      body = {:artist => artist}
      @@client.index index: index_name, type: 'artist', id: id, body: body.to_json
    end
  end
end