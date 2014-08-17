# Author:: MinixLi (gmail: MinixLi1986)
# Homepage:: http://citrus.inspawn.com
# Date:: 19 July 2014

require 'citrus/master/watchdog'
require 'citrus/modules/console_module'

module Citrus
  # ConsoleModules
  #
  #
  module ConsoleModules
    # MaterWatcher
    #
    #
    class MasterWatcher < ConsoleModule

      @module_id = '__master_watcher__'

      # Initialize the module
      #
      # @param [Hash]   args
      # @param [Object] console_service
      def initialize args={}, console_service
        @app = args[:app]
        @service = console_service
        @server_id = @app.server_id
        @watchdog = Master::WatchDog.new @app, @service
        @service.on('register') { |*args| on_server_add *args }
        @service.on('disconnect') { |*args| on_server_leave *args }
        @service.on('reconnect') { |*args| on_server_reconnect *args }
      end

      # Start the module
      def start &block
        block_given? and yield
      end

      # Master handler
      #
      # @param [Object] agent
      # @param [Hash]   msg
      def master_handler agent, msg, &block
        return if !msg
        case msg[:action]
        when 'subscribe'
          handle_subscribe agent, msg, &block
        else
        end
      end

      private

      # Server add listener
      #
      # @param [Hash] record
      # @private
      def on_server_add record
        return if !record || record[:type] == 'client' || !record[:server_type]
        @watchdog.add_server record
      end

      # Server leave listener
      #
      # @private
      def on_server_leave
      end

      # Server reconnect listener
      #
      # @private
      def on_server_reconnect
      end

      # Handle subscribe
      #
      # @param [Object] agent
      # @param [Hash]   msg
      #
      # @private
      def handle_subscribe agent, msg, &block
        return if !msg
        @watchdog.subscribe msg[:server_id]
        block_given? and yield nil, @watchdog.query
      end
    end
  end
end
