module Plex
  class Library
    include Plex::Base
    include Plex::Sortable

    def initialize(hash)
      @attributes = hash.except('Metadata')
      add_accessible_methods
    end

    def type
      attributes.fetch('type')
    end

    def locations
      attributes.fetch('Location', []).map {|l| l.fetch('path',nil) }.compact
    end

    def total_count(options = {})
      response = server.query(query_path(path), options.merge(page: 1, per_page: 0))
      response.fetch('totalSize').to_i
    end

    def all(options = {})
      get_entries('all', options)
    end

    def unwatched(options = {})
      get_entries('unwatched', options)
    end

    def newest(options = {})
      get_entries('newest', options)
    end

    def updated_since(time, options = {})
      results = self.all(options.except('page', 'per_page', :page, :per_page))
      sorted_results = results.sort {|a, b| b.updated_at <=> a.updated_at }
      valid_results, _ = results.partition {|a| Time.at(a.updated_at) > Time.at(time) }
      valid_results
    end

    def recently_added(options = {})
      get_entries('recentlyAdded', options)
    end

    def recently_viewed(options = {})
      get_entries('recentlyViewed', options)
    end

    def by_year(year, options = {})
      params = options.merge({ "type" => 1, "year" => year })
      get_entries('all', params)
    end

    def by_decade(decade, options = {})
      params = options.merge({ "type" => 1, "decade" => decade })
      get_entries('all', params)
    end

    def find_by_filename(filename)
      basename = File.basename(filename)
      all.detect do |movie|
        movie.medias.any? do |media|
          media.parts.any? do |part|
            File.basename(part.fetch('file','')) == basename
          end
        end
      end
    end

    def search(query, options = {})
      # search by filename
      # search by title
      # search by year?
      # search by ?
    end

    def to_hash
      hash = @attributes.dup
      hash.merge('locations' => locations, 'total_count' => total_count)
    end


    private


    def get_entries(path, options = {})
      raise StandardError, "Not implemented"
    end

    def sanitize_options(options)
      params = {}
      if options.key?(:sort)
        params['type'] = 1
        params['sort'] = SORT_ORDER.fetch(options[:sort], nil)
        if direction = options.fetch(:direction, nil)
          params['sort'] = params['sort'] + ":desc"
        end
      end
      params.merge(options.except(:sort, :direction))
    end

    def query_path(path)
      "/library/sections/#{key}/#{path}"
    end
  end
end