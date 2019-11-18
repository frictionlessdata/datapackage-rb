module DataPackage
  class Interpreter
    INFER_THRESHOLD = 10
    INFER_CONFIDENCE = 0.75
    YEAR_PATTERN = /[12]\d{3}/
    DATE_PATTERN = /(\d{1,2}[-\/]\d{1,2}[-\/]\d{2,4})|(\d{4}[-\/]\d{1,2}[-\/]\d{1,2})/
    DATETIME_PATTERN = /(\d{1,2}[-\/]\d{1,2}[-\/]\d{2,4}|\d{4}[-\/]\d{1,2}[-\/]\d{1,2}).\d{1,2}:\d{2}/
    TIME_PATTERN = /^\d{1,2}((:\d{1,2})|(am|pm|AM|PM))$/
    INTEGER_PATTERN = /^\d+$/
    DEFAULT_TYPE_FORMAT = {'type' => 'any', 'format' => 'default'}

    attr_reader :csv, :threshold

    def initialize(csv)
      @csv = csv
      @threshold = [csv.length, INFER_THRESHOLD].min
    end

    def type_and_format_at(header)
      values = csv.values_at(header).flatten
      counter = {}
      type_and_format = DEFAULT_TYPE_FORMAT

      values.each_with_index do |value, i|
        inspection_count = i + 1

        inspection = inspect_value(value)
        counter[inspection] = (counter[inspection] || 0) + 1
        if inspection_count >= threshold
          if counter[inspection] / inspection_count >= INFER_CONFIDENCE
            type_and_format = inspection
            break
          end
        end
      end

      type_and_format
    end

    def inspect_value(value)
      return DEFAULT_TYPE_FORMAT unless value.is_a?(String)

      if value.length == 4 && value.match(YEAR_PATTERN)
        return { 'type' => 'year', 'format' => 'default' }
      end

      if value.match(DATETIME_PATTERN)
        return { 'type' => 'datetime', 'format' => 'default' }
      end

      if value.match(DATE_PATTERN)
        return { 'type' => 'date', 'format' => 'default' }
      end

      if value.match(TIME_PATTERN)
        return { 'type' => 'time', 'format' => 'default' }
      end

      if value.match(INTEGER_PATTERN)
        return { 'type' => 'integer', 'format' => 'default' }
      end

      DEFAULT_TYPE_FORMAT
    end
  end
end
