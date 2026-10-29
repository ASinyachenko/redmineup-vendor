module ActionCable
  module Server
    class RupConfiguration < ActionCable::Server::Configuration
      def initialize(connection_klass: 'ActionCable::Connection::Base')
        super()

        @connection_class = -> { connection_klass.constantize }
        @logger ||= ::Rails.logger
        @disable_request_forgery_protection = true
      end

      def cable
        @cable ||= ActionCable.server.config.cable || { 'adapter' => 'async' }.with_indifferent_access
      end
    end
  end
end
