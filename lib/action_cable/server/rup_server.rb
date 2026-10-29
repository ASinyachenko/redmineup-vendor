module ActionCable
  module Server
    class RupServer < ActionCable::Server::Base
      BEAT_INTERVAL = 10

      attr_reader :config

      def initialize(config: self.class.config)
        @config = config
        @mutex = Monitor.new
        @remote_connections = @event_loop = @worker_pool = @pubsub = nil
      end

      def setup_heartbeat_timer
        @heartbeat_timer ||= event_loop.timer(BEAT_INTERVAL) do
          event_loop.post { connections.each(&:beat) }
        end
      end
    end
  end
end
