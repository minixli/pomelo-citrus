# Author:: MinixLi (gmail: MinixLi1986)
# Homepage:: http://citrus.inspawn.com
# Date:: 19 July 2014

require 'citrus/modules/console_module'

module Citrus
  # ConsoleModules
  #
  #
  module ConsoleModules
    # MaterWatcher
    #
    #
    class MonitorWatcher < ConsoleModule

      @module_id = '__monitor_watcher__'

      # Initialize the module
      #
      # @param [Hash]   args
      # @param [Object] console_service
      def initialize args={}, console_service
        @app = args[:app]
        @service = console_service
        @server_id = @app.server_id
      end

      # Start the module
      def start &block
        subscribe_request &block
      end

      # Monitor handler
      #
      # @param [Object] agent
      # @param [Hash]   msg
      def monitor_handler agent, msg, &block
        return if !msg || !msg[:action]
        case msg[:action]
        when 'add_server'
          handle_add_server agent, msg
        else
        end
      end

      private

      # Subscribe request
      #
      # @private
      def subscribe_request &block
        msg = { :action => 'subscribe', :server_id => @server_id }
        @service.agent.request ConsoleModules::MasterWatcher.module_id, msg, proc{ |err, servers|
          if err
            block_given? and yield err
            return
          end
          add_servers servers
          block_given? and yield
        }
      end

      # Handle add server
      #
      # @param [Object] agent
      # @param [Hash]   msg
      #
      # @private
      def handle_add_server agent, msg
        return if !msg || !msg[:server]
        add_servers [msg[:server]]
      end

      # Add servers
      #
      # @param [Array] sinfos
      #
      # @private
      def add_servers sinfos
        return unless sinfos && !sinfos.empty?
        @app.add_servers sinfos
      end
    end
  end
end
