module Redmineup
  module ActsAsVotable
    module Voter
      def voter?
        false
      end

      def up_acts_as_voter(*args)
        require 'redmineup/acts_as_votable/voter'
        include Redmineup::ActsAsVotable::Voter

        class_eval do
          def self.voter?
            true
          end
        end
      end
    end
  end
end
