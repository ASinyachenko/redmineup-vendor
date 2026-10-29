require File.dirname(__FILE__) + '/../test_helper'

class RupActsAsVoterTest < ActiveSupport::TestCase

  class NotVoter < ActiveRecord::Base; end
  def test_that_voter_returns_false_unless_included
    assert_equal NotVoter.voter?, false
  end

  def test_that_voter_returns_true_if_included
    assert_equal Voter.voter?, true
    assert_equal VotableVoter.voter?, true
  end
end
