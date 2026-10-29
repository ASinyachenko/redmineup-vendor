require File.dirname(__FILE__) + '/../test_helper'

class UpActsAsJournalizedTest < ActiveSupport::TestCase
  def setup
    @user = User.first || User.create!(login: 'journalist')
    @thing = JournalizedThing.create!(name: 'one', status: 'new')
  end

  def test_attribute_change_is_journaled
    @thing.init_journal(@user, 'why')
    @thing.update!(status: 'done')

    journal = @thing.journals.last
    assert_equal 'why', journal.notes
    assert_equal [%w(status new done)], journal.details.map { |d| [d.prop_key, d.old_value, d.value] }
  end

  def test_repeated_edits_keep_every_step
    %w(a b c).each do |status|
      @thing.init_journal(@user)
      @thing.update!(status: status)
    end

    assert_equal 3, @thing.journals.count
    assert_equal [%w(new a), %w(a b), %w(b c)], @thing.journals.order(:id).map { |j| [j.details.first.old_value, j.details.first.value] }
  end

  def test_several_changes_make_one_journal
    @thing.init_journal(@user)
    @thing.update!(status: 'done', due_date: Date.new(2026, 1, 1))

    assert_equal 1, @thing.journals.count
    assert_equal %w(due_date status), @thing.journals.first.details.map(&:prop_key).sort
  end

  def test_notes_only_journal
    @thing.init_journal(@user, 'just a note')
    @thing.save!

    assert_equal 1, @thing.journals.count
    assert_empty @thing.journals.first.details
  end

  def test_unchanged_save_without_notes_makes_no_journal
    @thing.init_journal(@user)
    @thing.save!

    assert_equal 0, @thing.journals.count
  end

  def test_no_journal_without_init_journal
    @thing.update!(status: 'done')

    assert_equal 0, @thing.journals.count
  end

  def test_rollback_leaves_no_journal
    JournalizedThing.transaction do
      @thing.init_journal(@user, 'x')
      @thing.update!(status: 'done')
      raise ActiveRecord::Rollback
    end

    assert_equal 0, Journal.where(journalized_type: 'JournalizedThing').count
  end

  def test_create_is_not_journaled_by_default
    thing = JournalizedThing.new(name: 'two', status: 'new')
    thing.init_journal(@user)
    thing.save!

    assert_equal 0, thing.journals.count
  end

  def test_excluded_and_counter_attributes_are_not_tracked
    names = @thing.journalized_attribute_names

    assert_includes names, 'status'
    assert_not_includes names, 'id'
    assert_not_includes names, 'updated_on'
    assert_not_includes names, 'comments_count'
  end

  def test_destroy_deletes_journals
    @thing.init_journal(@user, 'x')
    @thing.update!(status: 'done')

    assert_difference('Journal.count', -1) { @thing.destroy }
  end

  def test_unknown_option_is_rejected
    assert_raises(ArgumentError) { Class.new(ActiveRecord::Base) { self.table_name = 'journalized_things'; up_acts_as_journalized foo: 1 } }
  end

  def test_activity_needs_url
    assert_raises(ArgumentError) { Class.new(ActiveRecord::Base) { self.table_name = 'journalized_things'; up_acts_as_journalized activity: {} } }
  end

  def test_custom_field_values_fallback
    assert_equal [], @thing.custom_field_values
  end

  def test_registered
    assert_includes Redmineup::ActsAsJournalized.registry, 'JournalizedThing'
  end
end
