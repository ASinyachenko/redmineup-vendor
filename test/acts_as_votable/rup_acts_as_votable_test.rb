require File.dirname(__FILE__) + '/../test_helper'

class RupActsAsVotableTest < ActiveSupport::TestCase

  class NotVotable < ActiveRecord::Base; end
  def test_that_votable_returns_false_unless_included
    assert_equal NotVotable.votable?, false
  end

  def test_that_votable_returns_true_if_included
    assert_equal Votable.votable?, true
  end

  def test_behaves_like_votable_model
    assert Voter.create(:name => 'i can vote!')
    assert VotableCache.create(:name => 'voting model with cache')
    assert VotableVoter.create(:name => 'i can vote too!')
  end
end
