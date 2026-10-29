module Redmineup
  module Liquid
    module Filters
      module Arrays

        # Get the first element of the passed in array
        #
        # Example:
        #    {{ product.images | first | to_img }}
        # 
        #    {{ product.images | first: 3 }}
        #
        def first(array, count=1)
          (count > 1 ? array.first(count) : array.first) if array.respond_to?(:first)
        end

        # Convert the input into json string
        #
        # input - The Array or Hash to be converted
        #
        # Returns the converted json string
        def jsonify(input)
          as_liquid(input).to_json
        end

        # Group an array of items by a property
        #
        # input - the inputted Enumerable
        # property - the property
        #
        # Returns an array of Hashes, each looking something like this:
        #  {"name"  => "larry"
        #   "items" => [...] } # all the items where `property` == "larry"
        def group_by(input, property)
          if groupable?(input)
            input.group_by { |item| item_property(item, property).to_s }.each_with_object([]) do |item, array|
                array << {
                  "name"  => item.first,
                  "items" => item.last,
                  "size"  => item.last.size
                }
              end
          else
            input
          end
        end

        # Filter an array of objects
        #
        # input - the object array
        # property - property within each object to filter by
        # value - desired value
        #
        # Returns the filtered array of objects
        def where(input, property, value, operator='==')
          return input unless input.respond_to?(:select)
          input = input.values if input.is_a?(Hash)
          if operator == '=='
            input.select do |object|
              Array(item_property(object, property)).map(&:to_s).include?(value.to_s)
            end || []
          elsif operator == '<>'
            input.select do |object|
              !Array(item_property(object, property)).map(&:to_s).include?(value.to_s)
            end || []
          elsif operator == '>'
            input.select do |object|
              item_property_value = item_property(object, property) 
              item_property_value && item_property_value > value
            end || []
          elsif operator == '<'
            input.select do |object|
              item_property_value = item_property(object, property) 
              item_property_value && item_property_value < value
            end || []
          elsif operator == 'match'
            input.select do |object|
              Array(item_property(object, property)).map(&:to_s).any?{|i| i.match(value.to_s)}
            end || []
          elsif operator == 'any'
            input.select do |object|
              item_property(object, property).present?
            end || []
          elsif operator == 'none'
            input.select do |object|
              item_property(object, property).blank?
            end || []
          else
            []
          end
        end

        # Filters an array of objects against an expression
        #
        # input - the object array
        # variable - the variable to assign each item to in the expression
        # expression - a Liquid comparison expression passed in as a string
        #
        # Returns the filtered array of objects
        def where_exp(input, variable, expression)
          return input unless input.respond_to?(:select)

          input = input.values if input.is_a?(Hash) # FIXME

          condition = parse_condition(expression)
          @context.stack do
            input.select do |object|
              @context[variable] = object
              condition.evaluate(@context)
            end
          end || []
        end        

        # Filter an array of objects by tags
        #
        # input - the object array
        # tags - quoted tags list divided by comma
        # match - (all- defaut, any, exclude)
        #
        # Returns the filtered array of objects
        def tagged_with(input, tags, match='all')
          return input unless input.respond_to?(:select)
          input = input.values if input.is_a?(Hash)
          tag_list = tags.is_a?(Array) ? tags.sort : tags.split(',').map(&:strip).sort
          case match
          when "all"
            input.select do |object|
              object.respond_to?(:tag_list) &&
              (tag_list - Array(item_property(object, 'tag_list')).map(&:to_s).sort).empty?
            end || []
          when "any"
            input.select do |object|
              object.respond_to?(:tag_list) &&
              (tag_list & Array(item_property(object, 'tag_list')).map(&:to_s).sort).any?
            end || []
          when "exclude"
            input.select do |object|
              object.respond_to?(:tag_list) &&
              (tag_list & Array(item_property(object, 'tag_list')).map(&:to_s).sort).empty?
            end || []
          else
            []
          end
        end

        # Sort an array of objects
        #
        # input - the object array
        # property - property within each object to filter by
        # nils ('first' | 'last') - nils appear before or after non-nil values
        #
        # Returns the filtered array of objects
        def sort(input, property = nil, nils = "first")
          if input.nil?
            raise ArgumentError, "Cannot sort a null object."
          end
          if property.nil?
            input.sort
          else
            if nils == "first"
              order = - 1
            elsif nils == "last"
              order = + 1
            else
              raise ArgumentError, "Invalid nils order: " \
                "'#{nils}' is not a valid nils order. It must be 'first' or 'last'."
            end

            sort_input(input, property, order)
          end
        end

        def pop(array, input = 1)
          return array unless array.is_a?(Array)
          new_ary = array.dup
          new_ary.pop(input.to_i || 1)
          new_ary
        end

        def push(array, input)
          return array unless array.is_a?(Array)
          new_ary = array.dup
          new_ary.push(input)
          new_ary
        end

        def shift(array, input = 1)
          return array unless array.is_a?(Array)
          new_ary = array.dup
          new_ary.shift(input.to_i || 1)
          new_ary
        end

        def unshift(array, input)
          return array unless array.is_a?(Array)
          new_ary = array.dup
          new_ary.unshift(input)
          new_ary
        end

        private

        # Parse a string to a Liquid Condition
        def parse_condition(exp)
          parser    = ::Liquid::Parser.new(exp)
          condition = parse_binary_comparison(parser)

          parser.consume(:end_of_string)
          condition
        end        

        # Generate a Liquid::Condition object from a Liquid::Parser object additionally processing
        # the parsed expression based on whether the expression consists of binary operations with
        # Liquid operators `and` or `or`
        #
        #  - parser: an instance of Liquid::Parser
        #
        # Returns an instance of Liquid::Condition
        def parse_binary_comparison(parser)
          condition = parse_comparison(parser)
          first_condition = condition
          while (binary_operator = parser.id?("and") || parser.id?("or"))
            child_condition = parse_comparison(parser)
            condition.send(binary_operator, child_condition)
            condition =where_exp child_condition
          end
          first_condition
        end

        # Generates a Liquid::Condition object from a Liquid::Parser object based on whether the parsed
        # expression involves a "comparison" operator (e.g. <, ==, >, !=, etc)
        #
        #  - parser: an instance of Liquid::Parser
        #
        # Returns an instance of Liquid::Condition
        def parse_comparison(parser)
          left_operand = ::Liquid::Expression.parse(parser.expression)
          operator     = parser.consume?(:comparison)

          # No comparison-operator detected. Initialize a Liquid::Condition using only left operand
          return ::Liquid::Condition.new(left_operand) unless operator

          # Parse what remained after extracting the left operand and the `:comparison` operator
          # and initialize a Liquid::Condition object using the operands and the comparison-operator
          ::Liquid::Condition.new(left_operand, operator, ::Liquid::Expression.parse(parser.expression))
        end


      end # module ArrayFilters
    end
  end

  ::Liquid::Template.register_filter(Redmineup::Liquid::Filters::Arrays)
end