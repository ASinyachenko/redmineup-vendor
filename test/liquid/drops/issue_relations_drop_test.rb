require File.dirname(__FILE__) + '/../liquid_helper'
include LiquidHelperMethods

module Redmineup
  class IssueRelationsDropTest < ActiveSupport::TestCase
    def setup
      @issue_from = Issue.find_by(subject: 'Issue 3 subject')
      @issue_to = Issue.find_by(subject: 'Issue 4 subject')
      @relation = IssueRelation.create!(issue_from: @issue_from, issue_to: @issue_to, relation_type: 'precedes', delay: 1)
      @liquid_render = LiquidRender.new(
        'issue' => Liquid::IssueDrop.new(@issue_from)
      )
    end

    def test_relation_from_render
      issues_text = @liquid_render.render('{% for relation in issue.relations_from %} {{relation.issue_from.id}}|{{relation.issue_to.id}}|{{relation.relation_type}}|{{relation.delay}} {% endfor %}')
      assert_match "#{@issue_from.id}|#{@issue_to.id}|precedes|#{@relation.delay}", issues_text
    end

    def test_relation_size
      assert_equal '1', @liquid_render.render('{{ issue.relations_from.size }}')
    end
  end
end
