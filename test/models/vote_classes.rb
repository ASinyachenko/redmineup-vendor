class Voter < ActiveRecord::Base
  up_acts_as_voter
end

class Votable < ActiveRecord::Base
  up_acts_as_votable
  validates_presence_of :name
end

class VotableVoter < ActiveRecord::Base
  up_acts_as_votable
  up_acts_as_voter
end

class StiVotable < ActiveRecord::Base
  up_acts_as_votable
end

class ChildOfStiVotable < StiVotable
end

class StiNotVotable < ActiveRecord::Base
  validates_presence_of :name
end

class VotableChildOfStiNotVotable < StiNotVotable
  up_acts_as_votable
end

class VotableCache < ActiveRecord::Base
  up_acts_as_votable
  validates_presence_of :name
end
