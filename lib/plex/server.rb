module Plex

  class Server

    attr_reader :base_url, :headers, :config, :params

    VALID_PARAMS = %w| type year decade sort|

    def initialize(config)
      @config   = config
    end

    # Public Methods

    def libraries(options = {})
      results = query("library/sections", options)
      entries = results.fetch('Directory', [])
      entries.map {|entry| Plex::Library.new(entry) }
    end

    def library(query)
      library = if query.to_i.to_s == query || query.is_a?(Integer)
        libraries.detect {|s| s.id.to_i == query.to_i }
      else
        libraries.detect {|s| s.title == query }
      end
      raise NotFoundError, "Could not find Section with that ID or Name" if library.nil?
      library
    end

    def library_by_path(path)
      # detect full path
      path = File.dirname(File.join(path, 'foo.bar'))
      if found = libraries.detect {|l| l.directories.include?(path) }
        return found
      end

      # detect subpaths
      path_chunks = path.split("/").reject(&:empty?)
      (path_chunks.length-1).downto(1).each do |i|
        subpath = path_chunks[i]
        if found = libraries.detect {|l| l.directories.any? {|d| d.end_with?(subpath) } }
          return found
        end
      end
      nil
    end

    # /library/metadata/28191 or 28191
    def find(key)
      path = if key.is_a?(String) && key.starts_with?("/library/metadata")
        key
      else
        "/library/metadata/#{key}"
      end
      results = query(path)
      case results['size']
      when 1
        result = results["Metadata"].first
        model = result['type'] == 'movie' ? Plex::Movie : Plex::Show
        model.new(result)
      when 0
        p "No results found!"
      else
        raise StandardError, "Found #{results['size']} records for #{key}"
      end
    end


    def query(path, options = {})
      query_url     = query_path(path)
      query_params  = set_params(options)      
      response      = RestClient.get(query_url, query_params)
      response_hash = JSON.parse(response.body)
      response_hash.fetch('MediaContainer')
    rescue RestClient::Exception => e
      puts "Error: #{e.message}"
      puts "Url: #{query_url}"
      puts "query params: #{query_params}"
      puts response_hash
      raise
    # ensure
    #   p query_url, query_params
    end

    def query_path(path)
      path = path.gsub(/\A\//, '')
      File.join("#{config[:host]}:#{config[:port]}", path)
    end


    private

    def set_params(options)
      params = default_params.dup
      params.merge!(parse_query_params(options))
      params.merge!(pagination_params(options))
      params
    end

    def pagination_params(options)
      offset       = options.fetch(:page, 1).to_i - 1
      per_page     = options.fetch(:per_page, nil)
      return {} if per_page.nil?
        
      {
        "X-Plex-Container-Start" => offset * per_page,
        "X-Plex-Container-Size"  => per_page
      }
    end

    def parse_query_params(options)
      options = options.transform_keys(&:to_s)
      params = options.slice(*VALID_PARAMS)
      {"params" => params}
    end

    def default_params
      @default_params ||= {
        "X-Plex-Token" => config[:token],
        :accept        => :json
      }
    end
  end

end