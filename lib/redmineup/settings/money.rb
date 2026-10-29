require 'redmineup/settings'

module Redmineup
  class Settings
    class Money
      TAX_TYPE_EXCLUSIVE = 1
      TAX_TYPE_INCLUSIVE = 2

      class << self
        def default_currency
          Redmineup::Settings['default_currency'] || 'USD'
        end

        def major_currencies
          currencies = Redmineup::Settings['major_currencies'].to_s.split(',').select { |c| !c.blank? }.map(&:strip)
          currencies = %w[USD EUR GBP RUB CHF] if currencies.blank?
          currencies.compact.uniq
        end

        def default_tax
          Redmineup::Settings['default_tax'].to_f
        end

        def tax_type
          ((['1', '2'] & [Redmineup::Settings['tax_type'].to_s]).first || TAX_TYPE_EXCLUSIVE).to_i
        end

        def tax_exclusive?
          tax_type == TAX_TYPE_EXCLUSIVE
        end

        def thousands_delimiter
          ([' ', ',', '.'] & [Redmineup::Settings['thousands_delimiter']]).first
        end

        def decimal_separator
          ([',', '.'] & [Redmineup::Settings['decimal_separator']]).first
        end

        def disable_taxes?
          Redmineup::Settings['disable_taxes'].to_i > 0
        end
      end
    end
  end
end
