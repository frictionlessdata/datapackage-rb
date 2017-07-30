module DataPackage
  module Helpers

    # Dereference a resource that can be a URL or path to a JSON file or a hash
    # Returns a Hash with all values that are URLs or paths dereferenced

    def dereference_resource(resource, base_path: nil)
      case resource
      when Hash
        resource.inject({}) do |new_resource, (key, val)|
          new_resource[key] = dereference_resource(val, base_path: base_path)
          new_resource
        end
      when Enumerable
        resource.map{ |el| dereference_resource(el, base_path: base_path)}
      when String
        begin
          resolve_reference(resource, base_path: base_path, deep_dereference: true)
        rescue Errno::ENOENT
          resource
        end
      else
        resource
      end
    end

    # Try to resolve a reference to a JSON file
    # Returns a hash with the JSON
    # Raises JSON::ParserError, OpenURI::HTTPError, SocketError, TypeError for invalid references or JSON

    def resolve_reference(reference, deep_dereference: false, base_path: nil)
      # Try to extract JSON from file or webpage
      unless base_path.nil?
        reference = Pathname.new(base_path).join(Pathname.new(reference)).to_s
      end
      extracted_ref = load_json(reference)
      if deep_dereference == true
        dereference_resource(extracted_ref, base_path: base_path)
      else
        extracted_ref
      end
    end

    # Load JSON from path or URL;
    # Raises: Errno::ENOENT, OpenURI::HTTPError, SocketError, JSON::ParserError
    def load_json(schema_reference)
      json = open(schema_reference).read
      JSON.parse json
    end


    def base_path(path_or_url)
      path_or_url = path_or_url.to_s
      if path_or_url.empty?
        nil
      elsif path_or_url =~ /\A#{URI::regexp}\z/
        uri = URI.parse path_or_url
        return "#{uri.scheme}://#{uri.host}#{File.dirname uri.path}".chomp('/')
      else
        if File.directory?(path_or_url)
          return path_or_url
        else
          return File.expand_path File.dirname path_or_url
        end
      end
    end

  end
end
