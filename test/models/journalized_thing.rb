class JournalizedThing < ActiveRecord::Base
  scope :visible, lambda { |*| where('1=1') }

  up_acts_as_journalized except: :updated_on
end
