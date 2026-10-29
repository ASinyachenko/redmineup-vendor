class JournalDetail < ActiveRecord::Base
  belongs_to :journal
end

class Journal < ActiveRecord::Base
  belongs_to :journalized, :polymorphic => true
  belongs_to :issue, :foreign_key => :journalized_id

  belongs_to :user
  has_many :details, :class_name => 'JournalDetail', :dependent => :delete_all, :inverse_of => :journal

  attr_accessor :notify

  def initialize(*args)
    super
    if journalized
      journalized.new_record? ? self.notify = false : start
    end
  end

  def save(*args)
    journalize_changes
    (new_record? && notes.blank? && details.empty?) ? false : super()
  end

  def start
    @attributes_before_change = journalized.journalized_attribute_names.index_with { |name| journalized.send(name) }
    @custom_values_before_change = {}
    self
  end

  def journalize_changes
    if @attributes_before_change
      (journalized.journalized_attribute_names + @attributes_before_change.keys).uniq.each do |name|
        before = @attributes_before_change[name]
        after = journalized.send(name)
        next if before == after || (before.blank? && after.blank?)

        details << JournalDetail.new(property: 'attr', prop_key: name, old_value: before, value: after)
      end
    end
    start
  end
end
