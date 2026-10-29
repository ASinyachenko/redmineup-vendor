require_relative 'project'
require_relative 'user'

class Issue < ActiveRecord::Base
  belongs_to :project
  belongs_to :user
  belongs_to :author, class_name: 'User'

  has_many :relations_from, class_name: 'IssueRelation', foreign_key: 'issue_from_id', dependent: :delete_all
  has_many :relations_to, class_name: 'IssueRelation', foreign_key: 'issue_to_id', dependent: :delete_all
  has_many :journals, foreign_key: 'journalized_id'

  up_acts_as_draftable
  up_acts_as_taggable
  up_acts_as_viewed

  scope :visible, lambda { where('1=1') }

  def visible?
    true
  end

  def attachments
    Attachment.all
  end
end
