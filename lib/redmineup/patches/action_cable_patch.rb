module Redmineup
  module Patches
    module ActionCablePatch
      def self.prepended(base)
        base.class_eval do
          module_function def rup_server(klass = 'ActionCable::Connection::RupConnection')
            @rup_servers ||= {}
            return @rup_servers[klass] if @rup_servers[klass]

            config = ActionCable::Server::RupConfiguration.new(connection_klass: klass)
            @rup_servers[klass] = ActionCable::Server::RupServer.new(config: config)
          end
        end
      end
    end
  end
end

ActionCable.prepend(Redmineup::Patches::ActionCablePatch)
