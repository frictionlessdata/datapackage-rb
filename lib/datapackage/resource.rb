module DataPackage
  class Resource < Hash
    include DataPackage::Helpers

    # Public

    attr_reader :errors, :profile, :name, :source

    def self.infer(filepath)
      name = File.basename(filepath)
      if name[-4..-1] != '.csv'
        raise ResourceException.new('Inferrable resource must have .csv extension')
      end

      descr = {
        'format' => 'csv',
        'mediatype' => 'text/csv',
        'name' => name[0...-4],
        'path' => filepath,
        'schema' => {
          'fields' => []
        },
      }

      csv = CSV.read(filepath, headers: true)
      interpreter = DataPackage::Interpreter.new(csv)
      csv.headers.each do |header|
        field = { 'name' => header, 'type' => 'string'}
        field.merge! interpreter.type_and_format_at(header)
        descr['schema']['fields'] << field
      end

      new(descr)
    end

    def initialize(resource, base_path = '')
      self.merge! dereference_descriptor(resource, base_path: base_path,
        reference_fields: ['schema', 'dialect'])
      apply_defaults!
      @profile = DataPackage::Profile.new(self['profile'])
      @name = self.fetch('name')
      get_source!(base_path)
      apply_table_defaults! if self.tabular?
    end

    def valid?
      @profile.valid?(self)
    end

    alias :valid :valid?

    def validate
      @profile.validate(self)
    end

    def iter_errors
      @profile.iter_errors(self){ |err| yield err }
    end

    def descriptor
      self.to_h
    end

    def inline?
      @source_type == 'inline'
    end

    alias :inline :inline?

    def local?
      @source_type == 'local'
    end

    alias :local :local?

    def remote?
      @source_type == 'remote'
    end

    alias :remote :remote?

    def miltipart?
      false
    end

    alias :miltipart :miltipart?

    def tabular?
      tabular_profile = DataPackage::DEFAULTS[:resource][:tabular_profile]
      return true if @profile.name == tabular_profile
      return true if DataPackage::Profile.new(tabular_profile).valid?(self)
      false
    end

    alias :tabular :tabular?

    def headers
      if !tabular
        nil
      end
      get_table.headers
    end

    def schema
      if !tabular
        nil
      end
      get_table.schema
    end

    def iter(*args, &block)
      if !tabular
        message ='Methods iter/read are not supported for non tabular data'
        raise ResourceException.new message
      end
      get_table.iter(*args, &block)
    end

    def read(*args, &block)
      if !tabular
        message ='Methods iter/read are not supported for non tabular data'
        raise ResourceException.new message
      end
      get_table.read(*args, &block)
    end

    # Deprecated

    def table
      get_table
    end

    # Private

    private

    def get_source!(base_path)
      if self.fetch('data', nil)
        @source = self['data']
        @source_type = 'inline'
      elsif self.fetch('path', nil)
        unless is_safe_path?(self['path'])
          raise ResourceException.new "Path `#{self['path']}` is not safe"
        end
        @source = join_paths(base_path, self['path'])
        @source_type = is_fully_qualified_url?(@source) ? 'remote' : 'local'
      else
        raise ResourceException.new 'A resource descriptor must have a `path` or `data` property.'
      end
    end

    def get_table
      @table ||= TableSchema::Table.new(self.source, schema: self['schema']) if tabular?
    end

    def apply_defaults!
      self['profile'] ||= DataPackage::DEFAULTS[:resource][:profile]
      self['encoding'] ||= DataPackage::DEFAULTS[:resource][:encoding]
    end

    def apply_table_defaults!
      self['profile'] = DataPackage::DEFAULTS[:resource][:tabular_profile]
      if self.fetch('schema', nil)
        self['schema']['missingValues'] = DataPackage::DEFAULTS[:schema][:missing_values]
        self['schema'].fetch('fields', []).each do |field_descriptor|
          field_descriptor['type'] ||= DataPackage::DEFAULTS[:schema][:type]
          field_descriptor['format'] ||= DataPackage::DEFAULTS[:schema][:format]
        end
      end
      if self.fetch('dialect', nil)
        DataPackage::DEFAULTS[:dialect].each do |key, val|
          self['dialect'][key.to_s] ||= val
        end
      end
    end

  end
end
