require 'uri'
require 'rack'
require 'json'
require 'date'
require 'liquid'

module Redmineup
  module Liquid
    module Filters
      module Base
        include Redmineup::MoneyHelper

        def textilize(input)
          RedCloth3.new(input).to_html
        end

        def default(input, value)
          input.blank? ? value : input
        end

        def underscore(input)
          input.to_s.gsub(' ', '_').gsub('/', '_').underscore
        end

        def dasherize(input)
          input.to_s.gsub(' ', '-').gsub('/', '-').dasherize
        end

        def shuffle(array)
          array.to_a.shuffle
        end

        def random(input)
          rand(input.to_i)
        end

        def md5(input)
          Digest::MD5.hexdigest(input) unless input.blank?
        end

        def regex_replace(str, regex_search, value_replace)
          regex = /#{regex_search}/
          return str.gsub(regex, value_replace)
        end

        def regex_replace_once(str, regex_search, value_replace)
          regex = /#{regex_search}/
          return str.sub(regex, value_replace)
        end        

        # example:
        #   {{ "http:://www.example.com?key=hello world" | encode }}
        #
        #   => http%3A%3A%2F%2Fwww.example.com%3Fkey%3Dhello+world
        def encode(input)
          ::Rack::Utils.escape(input)
        end

        # example:
        #   {{ today | plus_days: 2 }}
        def plus_days(input, distanse)
          return '' if input.nil?
          days = distanse.to_i
          input.to_date + days.days rescue 'Invalid date'
        end

        # example:
        #   {{ today | date_range: '2015-12-12' }}
        def date_range(input, distanse)
          return '' if input.nil?
          (input.to_date - distanse.to_date).to_i rescue 'Invalid date'
        end

        # example:
        #   {{ now | utc }}
        def utc(input)
          return '' if input.nil?
          input.to_time.utc rescue 'Invalid date'
        end

        def modulo(input, operand)
          apply_operation(input, operand, :%)
        end

        def round(input, n = 0)
          result = to_number(input).round(to_number(n))
          result = result.to_f if result.is_a?(BigDecimal)
          result = result.to_i if n == 0
          result
        end

        def ceil(input)
          to_number(input).ceil.to_i
        end

        def floor(input)
          to_number(input).floor.to_i
        end

        def currency(input, currency_code = nil)
          price_to_currency(input, currency_code || container_currency, :converted => false)
        end

        def call_method(input, method_name)
          if input.respond_to?(method_name)
            input.method(method_name).call
          end
        end

        def custom_field(input, field_name)
          if input.respond_to?(:custom_field_values)
            custom_value = input.custom_field_values.detect { |cfv| cfv.custom_field.name == field_name }
            if custom_value
              result = custom_value.custom_field.format.formatted_custom_value(nil, custom_value)
              return result if result.respond_to?(:to_liquid)
              drop_class = "Redmineup::Liquid::#{result.class.name}Drop"
              Object.const_defined?(drop_class) ? drop_class.constantize.new(result) : result
            end
          end
        end

        def custom_fields(input)
          if input.respond_to?(:custom_field_values)
            input.custom_field_values.map { |cfv| cfv.custom_field.name }
          end
        end

        def attachment(input, file_name)
          if input.respond_to?(:attachments)
            if input.attachments.is_a?(Hash)
              attachment = input.attachments[file_name]
            else
              attachment = input.attachments.detect{|a| a.file_name == file_name}
            end
            AttachmentDrop.new attachment if attachment
          end
        end

        def multi_line(input)
          input.to_s.gsub("\n", '<br/>').html_safe
        end

        def concat(input, *args)
          result = input.to_s
          args.flatten.each { |a| result << a.to_s }
          result
        end

        # right justify and padd a string
        def rjust(input, integer, padstr = '')
          input.to_s.rjust(integer, padstr)
        end

        # left justify and padd a string
        def ljust(input, integer, padstr = '')
          input.to_s.ljust(integer, padstr)
        end

        def textile(input)
          ::RedCloth3.new(input).to_html
        end

        protected

        # Convert an array of properties ('key:value') into a hash
        # Ex: ['width:50', 'height:100'] => { :width => '50', :height => '100' }
        def args_to_options(*args)
          options = {}
          args.flatten.each do |a|
            if (a =~ /^(.*):(.*)$/)
              options[$1.to_sym] = $2
            end
          end
          options
        end

        # Write options (Hash) into a string according to the following pattern:
        # <key1>="<value1>", <key2>="<value2", ...etc
        def inline_options(options = {})
          return '' if options.empty?
          (options.stringify_keys.sort.to_a.collect { |a, b| "#{a}=\"#{b}\"" }).join(' ') << ' '
        end

        def sort_input(input, property, order)
          input.sort do |apple, orange|
            apple_property = item_property(apple, property)
            orange_property = item_property(orange, property)

            if !apple_property.nil? && orange_property.nil?
              - order
            elsif apple_property.nil? && !orange_property.nil?
              + order
            else
              apple_property <=> orange_property
            end
          end
        end

        def time(input)
          case input
          when Time
            input.clone
          when Date
            input.to_time
          when String
            Time.parse(input) rescue Time.at(input.to_i)
          when Numeric
            Time.at(input)
          else
            raise Errors::InvalidDateError,
              "Invalid Date: '#{input.inspect}' is not a valid datetime."
          end.localtime
        end

        def groupable?(element)
          element.respond_to?(:group_by)
        end

        def item_property(item, property)
          if item.respond_to?(:to_liquid)
            property.to_s.split(".").reduce(item.to_liquid) do |subvalue, attribute|
              subvalue[attribute]
            end
          elsif item.respond_to?(:data)
            item.data[property.to_s]
          else
            item[property.to_s]
          end
        end

        def as_liquid(item)
          case item
          when Hash
            pairs = item.map { |k, v| as_liquid([k, v]) }
            Hash[pairs]
          when Array
            item.map { |i| as_liquid(i) }
          else
            if item.respond_to?(:to_liquid)
              liquidated = item.to_liquid
              # prevent infinite recursion for simple types (which return `self`)
              if liquidated == item
                item
              else
                as_liquid(liquidated)
              end
            else
              item
            end
          end
        end

        def container
          @container ||= @context.registers[:container]
        end

        def container_currency
          container.currency if container.respond_to?(:currency)
        end
      end
      ::Liquid::Template.register_filter(Redmineup::Liquid::Filters::Base)
    end
  end
end
