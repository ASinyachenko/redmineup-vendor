module Redmineup
  module Patches
    module Compatibility
      module RoutingMapperPatch
        def constraints(options = {}, &block)
          return super(options, &block) unless options.is_a?(Hash)

          options[:object_type] = /.+/ if options[:object_type] && options[:object_type].is_a?(Regexp)
          super(options, &block)
        end
      end
    end
  end
end

ActionDispatch::Routing::Mapper.prepend(Redmineup::Patches::Compatibility::RoutingMapperPatch)
