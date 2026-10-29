module Redmineup
  module Patches
    module LiquidPatch
      module StandardFilters
        private

        def to_number(obj)
          case obj
          when Float
            BigDecimal(obj.to_s)
          when Numeric
            obj
          when String
            (obj.strip =~ /^\d+\.\d+$/) ? BigDecimal(obj) : obj.to_i
          else
            0
          end
        end
      end
    end
  end
end

Liquid::StandardFilters.prepend(Redmineup::Patches::LiquidPatch::StandardFilters)
