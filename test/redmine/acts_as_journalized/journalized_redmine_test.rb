require File.join(Dir.pwd, 'test/test_helper')

ActiveRecord::Base.connection.create_table :up_journalized_records, force: true do |t|
  t.references :project
  t.string :name
  t.date :due_date
  t.string :status
  t.integer :comments_count, default: 0
  t.datetime :created_on
  t.datetime :updated_on
end
Minitest.after_run { ActiveRecord::Base.connection.drop_table :up_journalized_records, if_exists: true }

class UpJournalizedRecordCustomField < CustomField
  def type_name
    :label_project_plural
  end
end

class UpJournalizedRecord < (defined?(ApplicationRecord) ? ApplicationRecord : ActiveRecord::Base)
  NOTIFIED = []

  belongs_to :project
  acts_as_customizable

  scope :visible, lambda { |user = User.current, _options = {}|
    joins(:project).where(Project.allowed_to_condition(user, :view_issues))
  }

  def visible?(user = User.current)
    user.allowed_to?(:view_issues, project)
  end

  up_acts_as_journalized(
    notify: ->(journal) { NOTIFIED << journal.id },
    edit_notes_permission: :edit_issues,
    activity: { type: 'up_records', url: ->(journal) { { controller: 'welcome' } }, title: ->(journal) { "Record #{journal.journalized.name}" } }
  )
end

Redmine::Activity.register :up_records, class_name: 'Redmineup::JournalEvent'

class UpActsAsJournalizedRedmineTest < ActiveSupport::TestCase
  fixtures :projects, :users, :email_addresses, :roles, :members, :member_roles, :enabled_modules, :trackers,
           :issue_statuses, :issues, :journals, :journal_details, :enumerations, :custom_fields, :custom_values,
           :projects_trackers, :watchers, :issue_categories, :versions

  def setup
    User.current = nil
    UpJournalizedRecord::NOTIFIED.clear
    @project = Project.find(1)
    @user = User.find(2)
    @field = UpJournalizedRecordCustomField.create!(
      name: 'Up tags', field_format: 'list', multiple: true, possible_values: %w(a b c), is_for_all: true
    )
    @record = UpJournalizedRecord.create!(project: @project, name: 'rec', status: 'new')
  end

  def test_attribute_and_notes
    @record.init_journal(@user, 'changed')
    @record.update!(status: 'done', due_date: Date.new(2026, 1, 2))

    journal = @record.journals.last
    assert_equal 'changed', journal.notes
    assert_equal %w(due_date status), journal.details.map(&:prop_key).sort
    assert_equal 'attr', journal.details.first.property
  end

  def test_multiple_value_custom_field
    @record.reload
    @record.init_journal(@user)
    @record.custom_field_values = { @field.id.to_s => %w(a b) }
    @record.save!

    @record.reload
    @record.init_journal(@user)
    @record.custom_field_values = { @field.id.to_s => %w(b c) }
    @record.save!

    details = @record.journals.order(:id).flat_map { |j| j.details.map { |d| [d.property, d.old_value, d.value] } }
    assert_includes details, ['cf', nil, 'a']
    assert_includes details, ['cf', nil, 'b']
    assert_includes details, ['cf', 'a', nil]
    assert_includes details, ['cf', nil, 'c']
  end

  def test_notes_only
    @record.init_journal(@user, 'only note')
    @record.save!

    assert_equal ['only note'], @record.journals.map(&:notes)
    assert_empty @record.journals.first.details
  end

  def test_unchanged_save_without_notes_has_no_journal
    @record.init_journal(@user)
    @record.save!

    assert_equal 0, @record.journals.count
  end

  def test_rollback_leaves_no_journal
    UpJournalizedRecord.transaction do
      @record.init_journal(@user, 'x')
      @record.update!(status: 'done')
      raise ActiveRecord::Rollback
    end

    assert_equal 0, Journal.where(journalized_type: 'UpJournalizedRecord').count
  end

  def test_create_with_journalize_create
    UpJournalizedRecord.up_journalized_options = UpJournalizedRecord.up_journalized_options.merge(journalize_create: true)
    record = UpJournalizedRecord.new(project: @project, name: 'new', status: 'open')
    record.init_journal(@user)
    record.save!

    keys = record.journals.first.details.map(&:prop_key)
    assert_includes keys, 'name'
    assert_includes keys, 'status'
  ensure
    UpJournalizedRecord.up_journalized_options = UpJournalizedRecord.up_journalized_options.except(:journalize_create)
  end

  def test_no_watchers_and_no_issue_mail
    ActionMailer::Base.deliveries.clear
    assert_no_difference 'Watcher.count' do
      @record.init_journal(@user, 'x')
      @record.update!(status: 'done')
    end
    assert_empty ActionMailer::Base.deliveries
  end

  def test_notify_callback_runs_after_commit
    @record.init_journal(@user, 'x')
    @record.update!(status: 'done')

    assert_equal [@record.journals.last.id], UpJournalizedRecord::NOTIFIED
  end

  def test_notify_callback_skipped_when_journal_notify_is_false
    @record.init_journal(@user, 'x').notify = false
    @record.update!(status: 'done')

    assert_empty UpJournalizedRecord::NOTIFIED
  end

  def test_issue_journals_are_unaffected
    ActionMailer::Base.deliveries.clear
    Setting.notified_events = %w(issue_updated)
    issue = Issue.find(1)
    issue.init_journal(@user, 'issue note')
    issue.update!(subject: 'changed subject')

    assert_equal 'issue note', issue.journals.last.notes
    assert_equal 'subject', issue.journals.last.details.first.prop_key
    assert_not_empty ActionMailer::Base.deliveries
  end

  def test_issue_visible_scope_ignores_journals_of_other_types
    @record.init_journal(@user, 'collision')
    @record.save!
    journal = @record.journals.last
    Journal.where(id: journal.id).update_all(journalized_id: 1)

    assert_not_includes Journal.visible(@user).pluck(:id), journal.id
    assert_includes Journal.visible(@user).pluck(:id), Journal.where(journalized_type: 'Issue', journalized_id: 1).first.id
  end

  def test_history_hides_custom_field_details_of_invisible_fields
    @field.update!(visible: false, role_ids: [])
    @record.reload
    @record.init_journal(@user)
    @record.custom_field_values = { @field.id.to_s => %w(a) }
    @record.save!

    journal = @record.journals.last
    assert_equal 1, journal.details.size
    assert_empty journal.visible_details(User.find(2))
    assert_equal 1, journal.visible_details(User.find(1)).size
  end

  def test_visible_for
    hidden = UpJournalizedRecord.create!(project: Project.find(2), name: 'hidden')
    [@record, hidden].each do |record|
      record.init_journal(@user, 'n')
      record.save!
    end
    Project.find(2).update!(is_public: false)
    Member.where(project_id: 2, user_id: @user.id).delete_all

    ids = Journal.visible_for(@user).pluck(:journalized_id, :journalized_type)
    assert_includes ids, [@record.id, 'UpJournalizedRecord']
    assert_not_includes ids, [hidden.id, 'UpJournalizedRecord']
    assert Journal.visible_for(@user).all? { |j| j.journalized_type == 'UpJournalizedRecord' }
  end

  def test_activity_event
    @record.init_journal(@user, 'visible note')
    @record.save!

    fetcher = Redmine::Activity::Fetcher.new(@user)
    fetcher.scope = ['up_records']
    event = fetcher.events(Date.today - 1, Date.today + 1).first

    assert_equal "Record rec", event.event_title
    assert_equal 'visible note', event.event_description
    assert_equal @record, event.event_group
  end

  def test_activity_is_limited_to_project
    other = UpJournalizedRecord.create!(project: Project.find(2), name: 'other')
    [@record, other].each do |record|
      record.init_journal(@user, 'n')
      record.save!
    end

    events = Redmineup::JournalEvent.find_events('up_records', User.find(1), nil, nil, project: Project.find(2))
    assert_equal [other], events.map(&:event_group)
  end

  def test_activity_only_notes_and_listed_keys
    @record.init_journal(@user)
    @record.update!(status: 'quiet')
    fetcher = Redmine::Activity::Fetcher.new(@user)
    fetcher.scope = ['up_records']
    assert_empty fetcher.events(Date.today - 1, Date.today + 1)

    UpJournalizedRecord.up_journalized_options = UpJournalizedRecord.up_journalized_options.merge(activity: UpJournalizedRecord.up_journalized_options[:activity].merge(keys: %w(status)))
    @record.init_journal(@user)
    @record.update!(status: 'loud')
    assert_equal 2, fetcher.events(Date.today - 1, Date.today + 1).size
  ensure
    UpJournalizedRecord.up_journalized_options = UpJournalizedRecord.up_journalized_options.merge(activity: UpJournalizedRecord.up_journalized_options[:activity].except(:keys))
  end

  def test_editable_by_and_update_notes
    @record.init_journal(@user, 'old')
    @record.update!(status: 'x')
    journal = @record.journals.last

    assert journal.editable_by?(User.find(2))
    assert_not journal.editable_by?(User.anonymous)
    assert journal.up_update_notes(@user, 'new')
    assert_equal 'new', journal.reload.notes
    assert_equal @user.id, journal.updated_by_id if journal.has_attribute?(:updated_by_id)
  end

  def test_journal_detail_escapes_deleted_custom_field_values
    detail = JournalDetail.new(property: 'cf', prop_key: '999999', old_value: '<b>old</b>', value: '<script>x</script>')
    html = ApplicationController.new.view_context.up_journal_detail(detail, @record.journals.build)

    assert_no_match(/<script>|<b>/, html)
  end

  def test_journal_detail_text
    @record.init_journal(@user)
    @record.update!(status: 'done')
    detail = @record.journals.last.details.first

    view = ApplicationController.new.view_context
    assert_match(/new/, view.up_journal_detail(detail, @record.journals.last, no_html: true))
  end
end
