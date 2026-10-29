module Redmineup
  module ActsAsPriceable
    module Base
      def up_acts_as_priceable(*args)
        priceable_options = args
        priceable_options << :price if priceable_options.empty?
        priceable_methods = ""
        priceable_options.each do |priceable_attr|
          priceable_methods << %(
            def #{priceable_attr.to_s}_to_s
              object_price(
                self,
                :#{priceable_attr},
                {
                  :decimal_mark => Redmineup::Settings::Money.decimal_separator,
                  :thousands_separator => Redmineup::Settings::Money.thousands_delimiter
                }
              ) if self.respond_to?(:#{priceable_attr})
            end
          )
        end

        class_eval <<-EOV
          include Redmineup::MoneyHelper

          #{priceable_methods}
        EOV
      end
    end
  end
end

ActiveRecord::Base.extend Redmineup::ActsAsPriceable::Base
