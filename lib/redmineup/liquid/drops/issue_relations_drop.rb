module Redmineup
  module Liquid
    class IssueRelationsDrop < ::Liquid::Drop
      def initialize(relations)
        @relations = relations
      end

      def all
        @all ||= @relations.map { |relation| IssueRelationDrop.new(relation) }
      end

      def visible
        @visible ||= @all.select(&:visible?)
      end

      def each(&block)
        all.each(&block)
      end

      def size
        @relations.size
      end
    end

    class IssueRelationDrop < ::Liquid::Drop
      delegate :relation_type, :delay, to: :@relation

      def initialize(relation)
        @relation = relation
      end

      def issue_from
        @issue_from ||= IssueDrop.new(@relation.issue_from)
      end

      def issue_to
        @issue_to ||= IssueDrop.new(@relation.issue_to)
      end
    end
  end
end
