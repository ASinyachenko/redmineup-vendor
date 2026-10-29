require 'liquid'

module Redmineup
  module Liquid
    module Filters
      module Colors
        def darken_color(input, value=0.4)
          Redmineup::ColorsHelper.darken_color(input, value.to_f)
        end

        def lighten_color(input, value=0.6)
          Redmineup::ColorsHelper.lighten_color(input, value.to_f)
        end

        def contrasting_text_color(input)
          Redmineup::ColorsHelper.contrasting_text_color(input)
        end

        def hex_color(input)
          Redmineup::ColorsHelper.hex_color(input)
        end

        def convert_to_brightness_value(input)
          Redmineup::ColorsHelper.convert_to_brightness_value(input)
        end

      end
      ::Liquid::Template.register_filter(Redmineup::Liquid::Filters::Colors)
    end
  end
end
