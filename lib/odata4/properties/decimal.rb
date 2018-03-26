module OData4
  module Properties
    # Defines the Decimal OData4 type.
    class Decimal < OData4::Property
      # Returns the property value, properly typecast
      # @return [BigDecimal,nil]
      def value
        if (@value.nil? || @value.empty?) && (strict? && allows_nil?)
          nil
        else
          BigDecimal(@value)
        end
      end

      # Sets the property value
      # @params new_value something BigDecimal() can parse
      def value=(new_value)
        validate(BigDecimal(new_value.to_s))
        @value = new_value.to_s
      end

      # The OData4 type name
      def type
        'Edm.Decimal'
      end

      # Value to be used in URLs.
      # @return [String]
      def url_value
        value.to_f.to_s
      end

      # Value to be used in JSON payloads
      # @return [Float]
      def json_value
        if value
          value.to_f
        else
          nil
        end
      end

      private

      def validate(value)
        if value > max_value || value < min_value || value.precs.first > 29
          validation_error "Value is outside accepted range: #{min_value} to #{max_value}, or has more than 29 significant digits"
        end
      end

      def min_value
        @min ||= BigDecimal(-7.9 * (10**28), 2)
      end

      def max_value
        @max ||= BigDecimal(7.9 * (10**28), 2)
      end
    end
  end
end
