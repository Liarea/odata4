require 'uri'
require 'date'
require 'time'
require 'bigdecimal'
require 'nokogiri'
require 'faraday'
require 'andand'
require 'json'
require 'logger'

# require 'active_support'
# require 'active_support/core_ext'
# require 'active_support/concern'
require 'core_extensions'
require 'core_extensions/hash'
require 'core_extensions/hash/compacting'

require 'odata4/version'
require 'odata4/property_registry'
require 'odata4/property'
require 'odata4/properties'
require 'odata4/navigation_property'
require 'odata4/entity'
require 'odata4/entity_container'
require 'odata4/entity_set'
require 'odata4/query'
require 'odata4/schema'
require 'odata4/service'
require 'odata4/service_registry'

require 'odata4/railtie' if defined?(::Rails)

# The OData4 gem provides a convenient way to interact with OData4 services from
# Ruby. Please look to the {file:README.md README} for how to get started using
# the OData4 gem.
module OData4
end
