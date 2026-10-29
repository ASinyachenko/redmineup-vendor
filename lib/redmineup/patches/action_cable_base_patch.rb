module Redmineup
  module Patches
    module ActionCableBasePatch
      def self.prepended(base)
        base.extend(ClassMethods)
        base.delegate :rup_broadcast_to, to: :class
      end

      module ClassMethods
        def rup_broadcast_to(*args)
          # TODO: Remove to 2 args after plugins update
          if args.length == 3
            klass, model, message = args
            ActionCable.rup_server(klass).broadcast(broadcasting_for(model), message)
          else
            model, message = args
            ActionCable.rup_server.broadcast(broadcasting_for(model), message)
          end
        end
      end
    end
  end
end

ActionCable::Channel::Base.prepend(Redmineup::Patches::ActionCableBasePatch)
