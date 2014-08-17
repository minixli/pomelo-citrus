# Author:: MinixLi (gmail: MinixLi1986)
# Homepage:: http://citrus.inspawn.com
# Date:: 22 July 2014

module Citrus
  # Master
  #
  #
  module Master
    # WatchDog
    #
    #
    class WatchDog
      # Create a new watchdog
      #
      # @param [Object] app
      # @param [Object] console_service
      def initialize app, console_service
        @app = app
        @service = console_service
        @servers = {}
        @listeners = []
      end

      # Add server
      #
      # @param [Hash] server
      def add_server server
        return unless server
        @servers[server[:server_id]] = server
        notify({ :action => 'add_server', :server => server })
      end

      # Remove server
      def remove_server
      end

      # Reconnect server
      def reconnect_server
      end

      # Subscribe
      #
      # @param [String] server_id
      def subscribe server_id
        @listeners << server_id
      end

      # Unsubscribe
      #
      # @param [String] server_id
      def unsubscribe server_id
        @listeners.delete server_id
      end

      # Query
      def query
        @servers.values
      end

      private

      # Notify
      #
      # @param [Hash] msg
      #
      # @private
      def notify msg
        @listeners.each { |server_id|
          @service.agent.notify server_id, ConsoleModules::MonitorWatcher.module_id, msg
        }
      end

      # Notify
      #
      # @param [String] server_id
      # @param [Hash] msg
      def notify_by_id server_id, msg
        @service.agent.notify server_id, ConsoleModules::MonitorWatcher.module_id, msg
      end
    end
  end
end
