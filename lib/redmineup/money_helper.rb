require 'action_view'
require 'redmineup/settings/money'

module Redmineup
  module MoneyHelper
    def object_price(obj, price_field = :price, options = {})
      options.merge!({:symbol => true})
      price_to_currency(obj.try(price_field), obj.currency, options).to_s if obj.respond_to?(:currency)
    end

    def prices_formatted_collection(prices_collection, options = {})
      return [] if prices_collection.blank? || prices_collection == 0
      prices = prices_collection
      prices.reject!{|k, v| v.to_i == 0} if options[:hide_zeros]
      prices.map { |k, v| price_to_currency(v, k, symbol: true) }.compact
    end

    def prices_collection_by_currency(prices_collection, options = {})
      formatted_prices = prices_formatted_collection(prices_collection, options)

      formatted_prices.map do |formatted_price|
        content_tag(:span, formatted_price, :style => "white-space: nowrap;")
      end
    end

    def deal_currency_icon(currency)
      case currency.to_s.upcase
      when 'EUR'
        'icon-money-euro'
      when 'GBP'
        'icon-money-pound'
      when 'JPY'
        'icon-money-yen'
      else
        'icon-money-dollar'
      end
    end

    def collection_for_currencies_select(default_currency = Redmineup::Settings::Money.default_currency, major_currencies = Redmineup::Settings::Money.major_currencies)
      currencies = []
      currencies << default_currency.to_s unless default_currency.blank?
      currencies |= major_currencies
      currencies.map do |c|
        currency = Redmineup::Currency.find(c)
        ["#{currency.iso_code} (#{currency.symbol})", currency.iso_code] if currency
      end.compact.uniq
    end

    def all_currencies
      Currency.table.inject([]) do |array, (_, attributes)|
        array ||= []
        array << [attributes[:name].to_s + (attributes[:symbol].blank? ? '' : " (#{attributes[:symbol]})"), attributes[:iso_code]]
        array
      end.sort{|x, y| x[0] <=> y[0]}
    end

    def price_to_currency(price, currency = Redmineup::Settings::Money.default_currency, options = {})
      return '' if price.blank?

      currency = 'USD' unless currency.is_a?(String)
      default_options = {
        decimal_mark: Redmineup::Settings::Money.decimal_separator,
        thousands_separator: Redmineup::Settings::Money.thousands_delimiter
      }.reject { |_k, v| v.nil? }

      currency = Redmineup::Currency.find(currency)
      Redmineup::Currency.format(price.to_f, currency, default_options.merge(options))
    end
  end
end

unless ActionView::Base.included_modules.include?(Redmineup::MoneyHelper)
  ActionView::Base.send(:include, Redmineup::MoneyHelper)
end
