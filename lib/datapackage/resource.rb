module DataPackage
  class Resource < Hash
    include DataPackage::Helpers

    attr_reader :name, :profile, :source, :source_type, :valid, :errors

    def initialize(resource, base_path = '')
      self.merge! dereference_descriptor(resource, base_path: base_path,
        reference_fields: ['schema', 'dialect'])
      apply_defaults!
      @profile = DataPackage::Profile.new(self['profile'])
      @name = self['name']
      get_source!(base_path)
      apply_table_defaults! if self.tabular?
    end

    def table
      @table ||= TableSchema::Table.new(self.source, self['schema']) if tabular?
    end

    def tabular?
      tabular_profile = DataPackage::DEFAULTS[:resource][:tabular_profile]
      return true if @profile.name == tabular_profile
      return true if DataPackage::Profile.new(tabular_profile).valid?(self)
      false
    end

    alias :tabular :tabular?

    def valid?
      validate
      @valid
    end

    def validate
      @errors = @profile.validate(self)
      @valid = @profile.valid?(self)
    end

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

    def apply_defaults!
      self['profile'] ||= DataPackage::DEFAULTS[:resource][:profile]
      self['encoding'] ||= DataPackage::DEFAULTS[:resource][:encoding]
    end

    def apply_table_defaults!
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
