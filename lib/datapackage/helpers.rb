module DataPackage
  module Helpers

    # Dereference a resource that can be a URL or path to a JSON file or a hash
    # Returns a Hash with all values that are URLs, paths or JSON pointers dereferenced

    def dereference_resource(resource, parent_object: nil, base_path: nil)
      case resource
      when Hash
        resource.inject({}) do |new_resource, (key, val)|
          case key
          when '$schema'
            new_resource[key] = val
          when '$ref'
            dereferenced = dereference_resource(val, base_path: base_path,
              parent_object: parent_object || resource)
            if dereferenced.is_a?(Hash)
              new_resource.delete(key)
              new_resource.merge!(dereferenced)
            else
              new_resource = dereferenced
            end
          else
            dereferenced = dereference_resource(val, base_path: base_path,
              parent_object: parent_object || resource)
            new_resource[key] = dereferenced
          end
          new_resource
        end
      when Enumerable
        resource.map{ |el| dereference_resource(el, parent_object: parent_object, base_path: base_path)}
      when String
        begin
          resolve_reference(resource, parent_object: parent_object, base_path: base_path)
        rescue ReferenceException
          resource
        end
      else
        resource
      end
    end

    # Try to resolve a reference to a JSON file
    # Returns a hash with the JSON
    # Raises JSON::ParserError, OpenURI::HTTPError, SocketError, TypeError for invalid references or JSON

    def resolve_reference(reference, parent_object: nil, deep_dereference: true, base_path: nil)
      # Try to extract JSON from file or webpage
      extracted_ref = load_json(reference)
      base_path = base_path(reference) if parent_object.nil?
      if deep_dereference == true
        dereference_resource(extracted_ref, parent_object: parent_object, base_path: base_path)
      else
        extracted_ref
      end
      rescue Errno::ENOENT
        # Check if this is a JSON reference
        extracted_ref = dereferece_pointer(reference, parent_object: parent_object, base_path: base_path)
        if deep_dereference == true
          dereference_resource(extracted_ref, parent_object: parent_object, base_path: base_path)
        else
          resolved_pointer
        end
    end

    # Try to resolve a JSON reference
    # Returns a hash with the JSON
    # Raises ReferenceException if a JSON pointer couldn't be resolved

    def dereferece_pointer(reference, parent_object: nil, base_path: nil)
      reference_error = ReferenceException.new("Couldn't resolve reference `#{reference}`")
      filename, json_reference = reference.split '#'
      raise reference_error if json_reference.nil?
      pointer = Hana::Pointer.new(json_reference)
      unless filename.empty?
        filepath = Pathname.new(base_path).join(Pathname.new(filename)).to_s
        parent_object = resolve_reference(filepath)
      end
      resolved_pointer = pointer.eval(parent_object)
      raise reference_error if resolved_pointer.nil?
      resolved_pointer
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
