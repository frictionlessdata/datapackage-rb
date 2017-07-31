module DataPackage
  module Helpers

    # Dereference a resource that can be a URL or path to a JSON file or a hash
    # Returns a Hash with all values that are URLs or paths dereferenced
    def dereference_descriptor(resource, base_path: nil, reference_fields: nil)
      case resource
      when Hash
        resource.inject({}) do |new_resource, (key, val)|
          if reference_fields.nil? || reference_fields.include?(key)
            new_resource[key] = dereference_descriptor(val, base_path: base_path,
              reference_fields: reference_fields)
          else
            new_resource[key] = val
          end
          new_resource
        end
      when Enumerable
        resource.map{ |el| dereference_descriptor(el, base_path: base_path, reference_fields: reference_fields)}
      when String
        begin
          resolve_json_reference(resource, base_path: base_path, deep_dereference: true)
        rescue Errno::ENOENT
          resource
        end
      else
        resource
      end
    end

    # Resolve a reference to a JSON file; Returns the JSON as hash
    # Raises JSON::ParserError, OpenURI::HTTPError, SocketError, TypeError for invalid references or JSON
    def resolve_json_reference(reference, deep_dereference: false, base_path: nil)
      # Try to extract JSON from file or webpage
      reference = join_paths(base_path, reference)
      extracted_ref = load_json(reference)
      if deep_dereference == true
        dereference_descriptor(extracted_ref, base_path: base_path)
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

    def join_paths(base_path, resource)
      if base_path.nil? || base_path.empty?
        resource
      elsif base_path =~ /\A#{URI::regexp}\z/
        URI.join(base_path, resource)
      elsif File.directory?(base_path)
        File.join(base_path, resource)
      elsif File.file?(base_path)
        base_path
      else
        resource
      end
    end

  end
end
