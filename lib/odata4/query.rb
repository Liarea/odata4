require 'odata4/query/criteria'
require 'odata4/query/in_batches'

module OData4
  # OData4::Query provides the query interface for requesting Entities matching
  # specific criteria from an OData4::EntitySet. This class should not be
  # instantiated directly, but can be. Normally you will access a Query by
  # first asking for one from the OData4::EntitySet you want to query.
  class Query
    attr_reader :options

    include InBatches

    # Create a new Query for the provided EntitySet
    # @param entity_set [OData4::EntitySet]
    # @param options [Hash] Query options
    def initialize(entity_set, options = {})
      @entity_set = entity_set
      @options    = options
      setup_empty_criteria_set
    end

    # Instantiates an OData4::Query::Criteria for the named property.
    # @param property [to_s]
    def [](property)
      property_instance = @entity_set.new_entity.get_property(property)
      property_instance = property if property_instance.nil?
      OData4::Query::Criteria.new(property: property_instance)
    end

    # Find the Entity with the supplied key value.
    # @param key [to_s] primary key to lookup
    # @return [OData4::Entity,nil]
    def find(key)
      entity = @entity_set.new_entity
      key_property = entity.get_property(entity.primary_key)
      key_property.value = key

      pathname = "#{entity_set.name}(#{key_property.url_value})"
      query = [pathname, assemble_criteria].compact.join('?')
      execute(query).first
    end

    def find_by(**params)
      entity = @entity_set.new_entity
      return nil if params.keys.eql? entity.compound_keys
      key_properties = params.keys.map do |key|
        property = entity.get_property(key)
        property.value = params[key]
        property
      end

      pathname = "#{entity_set.name}(#{url_for_properties(key_properties)})"
      query = [pathname, assemble_criteria].compact.join('?')
      execute(query).first
    end

    def url_for_properties(key_properties)
      key_properties.map { |key_prop| ["#{key_prop.name}=#{key_prop.url_value}"] }.join(',')
    end

    # Adds a filter criteria to the query.
    # For filter syntax see https://msdn.microsoft.com/en-us/library/gg309461.aspx
    # Syntax:
    #   Property Operator Value
    #
    # For example:
    #   Name eq 'Customer Service'
    #
    # Operators:
    # eq, ne, gt, ge, lt, le, and, or, not
    #
    # Value
    #  can be 'null', can use single quotes
    # @param criteria
    def where(criteria)
      criteria_set[:filter] << criteria
      self
    end

    # Adds a fulltext search term to the query
    # NOTE: May not be implemented by the service
    # @param term [String]
    def search(term)
      criteria_set[:search] << term
      self
    end

    # Adds a filter criteria to the query with 'and' logical operator.
    # @param criteria
    #def and(criteria)
    #
    #end

    # Adds a filter criteria to the query with 'or' logical operator.
    # @param criteria
    #def or(criteria)
    #
    #end

    # Specify properties to order the result by.
    # Can use 'desc' like 'Name desc'
    # @param properties [Array<Symbol>]
    # @return [self]
    def order_by(*properties)
      criteria_set[:orderby] += properties
      self
    end

    # Specify associations to expand in the result.
    # @param associations [Array<Symbol>]
    # @return [self]
    def expand(*associations)
      criteria_set[:expand] += associations
      self
    end

    # Specify properties to select within the result.
    # @param properties [Array<Symbol>]
    # @return [self]
    def select(*properties)
      criteria_set[:select] += properties
      self
    end

    # Add skip criteria to query.
    # @param value [to_i]
    # @return [self]
    def skip(value)
      criteria_set[:skip] = value.to_i
      self
    end

    # Add limit criteria to query.
    # @param value [to_i]
    # @return [self]
    def limit(value)
      criteria_set[:top] = value.to_i
      self
    end

    # Add inline count criteria to query.
    # Not Supported in CRM2011
    # @return [self]
    def include_count
      criteria_set[:inline_count] = true
      self
    end

    # Convert Query to string.
    # @return [String]
    def to_s
      [entity_set.name, assemble_criteria].compact.join('?')
    end

    # Execute the query.
    # @return [OData4::Service::Response]
    def execute(url_chunk = self.to_s)
      service.execute(url_chunk, options.merge(query: self))
    end

    # Executes the query to get a count of entities.
    # @return [Integer]
    def count
      url_chunk = ["#{entity_set.name}/$count", assemble_criteria].compact.join('?')
      response = self.execute(url_chunk)
      # Some servers (*cough* Microsoft *cough*) seem to
      # return extraneous characters in the response.
      response.body.scan(/\d+/).first.to_i
    end

    # Checks whether a query will return any results by calling #count
    # @return [Boolean]
    def empty?
      self.count == 0
    end

    # The EntitySet for this query.
    # @return [OData4::EntitySet]
    # @api private
    def entity_set
      @entity_set
    end

    # The service for this query
    # @return [OData4::Service]
    # @api private
    def service
      @service ||= entity_set.service
    end

    private

    def criteria_set
      @criteria_set
    end

    def setup_empty_criteria_set
      @criteria_set = {
        filter:       [],
        search:       [],
        select:       [],
        expand:       [],
        orderby:      [],
        skip:         0,
        top:          0,
        inline_count: false
      }
    end

    def assemble_criteria
      criteria = [
        filter_criteria,
        search_criteria,
        list_criteria(:orderby),
        list_criteria(:expand),
        list_criteria(:select),
        inline_count_criteria,
        paging_criteria(:skip),
        paging_criteria(:top)
      ].compact!

      criteria.empty? ? nil : criteria.join('&')
    end

    def filter_criteria
      return nil if criteria_set[:filter].empty?
      filters = criteria_set[:filter].collect(&:to_s)
      "$filter=#{filters.join(' and ')}"
    end

    def search_criteria
      return nil if criteria_set[:search].empty?
      filters = criteria_set[:search].collect(&:to_s)
      "$search=#{filters.join(' AND ')}"
    end

    def list_criteria(name)
      criteria_set[name].empty? ? nil : "$#{name}=#{criteria_set[name].join(',')}"
    end

    # inlinecount not supported by Microsoft CRM 2011
    def inline_count_criteria
      criteria_set[:inline_count] ? '$count=true' : nil
    end

    def paging_criteria(name)
      criteria_set[name] == 0 ? nil : "$#{name}=#{criteria_set[name]}"
    end
  end
end
