module Redmineup
  module Liquid
    class CustomFieldEnumerationDrop < ::Liquid::Drop
      delegate :id, :to_s, to: :@enumeration

      def initialize(enumeration)
        @enumeration = enumeration
      end
    end
  end
end