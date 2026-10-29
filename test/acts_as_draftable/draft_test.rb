require File.expand_path('../../test_helper', __FILE__)

class DraftTest < ActiveSupport::TestCase
  def test_restore
    issue = Issue.new(subject: 'some subject', description: 'some description')

    issue.save_draft
    restored_issue = Redmineup::ActsAsDraftable::Draft.find(issue.draft_id).restore

    assert_equal issue.subject, restored_issue.subject
    assert_equal issue.description, restored_issue.description
  end

  def test_restore_all
    first_issue = Issue.new(subject: 'first subject')
    first_issue.save_draft
    second_issue = Issue.new(subject: 'second subject')
    second_issue.save_draft

    restored_issues = Redmineup::ActsAsDraftable::Draft.restore_all
    assert_equal [first_issue.subject, second_issue.subject], restored_issues.map(&:subject).sort
  end

  private

  def current_user
    users(:sam)
  end
end
