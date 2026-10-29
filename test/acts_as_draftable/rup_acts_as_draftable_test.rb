require File.expand_path('../../test_helper', __FILE__)

class RupActsAsDraftableTest < ActiveSupport::TestCase
  def test_up_acts_as_draftable_without_arguments
    assert_nothing_raised do
      Project.up_acts_as_draftable
    end
  end

  def test_up_acts_as_draftable_with_parent
    assert_nothing_raised do
      News.up_acts_as_draftable(parent: :author)
    end
    assert User.new.respond_to?(:drafts)
  end

  def test_up_acts_as_draftable_with_non_existing_parent
    assert_raises do
      Issue.up_acts_as_draftable(parent: :foo)
    end
  end

  def test_up_acts_as_draftable_with_non_hash_argument
    assert_raises do
      Issue.up_acts_as_draftable('bar')
    end
  end

  def test_up_acts_as_draftable_with_invalid_hash_key
    assert_raises do
      Issue.up_acts_as_draftable(baz: 'qux')
    end
  end

  def test_drafts
    Issue.up_acts_as_draftable parent: :project
    issue = Issue.new
    issue.save_draft

    assert_equal 1, Issue.drafts(current_user).count
    assert_equal Redmineup::ActsAsDraftable::Draft, Issue.drafts(current_user).first.class
  end

  def test_from_draft
    Issue.up_acts_as_draftable parent: :project
    issue = Issue.new(subject: 'subject')
    issue.save_draft

    issue_from_draft = Issue.from_draft(issue.draft_id)

    assert_equal Issue, issue_from_draft.class
    assert_equal true, issue_from_draft.new_record?
    assert_equal issue.draft_id, issue_from_draft.draft_id

    assert_equal issue.subject, issue_from_draft.subject
  end

  def test_draft_deleted_after_save
    issue = Issue.new(subject: 'subject')
    issue.save_draft

    issue_from_draft = Issue.from_draft(issue.draft_id)

    assert_difference 'Issue.count' do
      assert_difference 'Redmineup::ActsAsDraftable::Draft.count', -1 do
        issue_from_draft.save!
      end
    end
    assert_nil issue_from_draft.draft_id
  end

  def test_from_draft_with_non_existing_draft_id
    assert_raises do
      Issue.from_draft(999)
    end
  end

  def test_from_draft_with_wrong_type
    Project.up_acts_as_draftable

    project = Project.new
    project.save_draft

    assert_raises do
      Issue.from_draft(project.draft_id)
    end
  end

  def test_dump_to_draft
    assert_equal String, Issue.new.dump_to_draft.class
  end

  def test_load_from_draft
    attributes = {subject: 'subject', description: 'description'}
    draft = Issue.new(attributes).dump_to_draft

    issue = Issue.new
    issue.load_from_draft(draft)

    assert_equal attributes[:subject], issue.subject
    assert_equal attributes[:description], issue.description
  end

  def test_save_draft
    Issue.up_acts_as_draftable parent: :project
    attributes = { subject: 'subject' }
    issue = Issue.new(attributes)

    assert_no_difference 'Issue.count' do
      assert_difference 'Redmineup::ActsAsDraftable::Draft.count' do
        result = issue.save_draft
        assert_equal true, result
      end
    end
    assert_not_nil issue.draft_id

    draft = Redmineup::ActsAsDraftable::Draft.find(issue.draft_id)
    assert_equal 'Issue', draft.target_type
    assert_equal current_user.id, draft.user_id
    assert_equal attributes[:subject], draft.restore.subject
  end

  def test_save_draft_with_associations
    Issue.up_acts_as_draftable parent: :project
    issue = Issue.new(project: projects(:second_project))
    issue.save_draft

    draft = Redmineup::ActsAsDraftable::Draft.find(issue.draft_id)
    assert_equal issue.project.name, draft.restore.project.name
  end

  def test_save_draft_updates_existing_draft
    Issue.up_acts_as_draftable parent: :project
    issue = Issue.new
    issue.save_draft

    issue.subject = 'changed subject'
    assert_no_difference 'Issue.count' do
      assert_no_difference 'Redmineup::ActsAsDraftable::Draft.count' do
        issue.save_draft
      end
    end

    draft = Redmineup::ActsAsDraftable::Draft.find(issue.draft_id)
    assert_equal issue.subject, draft.restore.subject
  end

  def test_save_draft_does_not_save_persisted_object
    issue = issues(:second_issue)
    assert_equal false, issue.save_draft
  end

  def test_save_draft_saves_persisted_but_changed_object
    issue = issues(:second_issue)
    issue.subject = 'changed subject'
    assert_equal true, issue.save_draft
  end

  def test_update_draft
    issue = Issue.new(subject: 'subject')
    issue.save_draft

    assert_no_difference 'Issue.count' do
      assert_no_difference 'Redmineup::ActsAsDraftable::Draft.count' do
        issue.update_draft(subject: 'updated_subject')
      end
    end

    draft = Redmineup::ActsAsDraftable::Draft.find(issue.draft_id)
    assert_equal issue.subject, draft.restore.subject
  end

  private

  def current_user
    users(:sam)
  end
end
