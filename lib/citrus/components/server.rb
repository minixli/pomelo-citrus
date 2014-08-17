# Author:: MinixLi (gmail: MinixLi1986)
# Homepage:: http://citrus.inspawn.com
# Date:: 17 July 2014

require 'citrus/components/component'
require 'citrus/server/server'

module Citrus
  # Components
  #
  #
  module Components
    # Server
    #
    #
    class Server < Component
      @name = 'server'

      # Initialize the component
      #
      # @param [Object] app
      def initialize app
        @server = Citrus::Server::Server.new app
      end

      # Start the component
      def start &block
        @server.start
        EM.next_tick { block_given? and yield }
      end

      # Component lifecycle callback
      def after_start &block
        @server.after_start
        EM.next_tick { block_given? and yield }
      end

      # Stop the component
      def stop force=false, &block
        @server.stop
        EM.next_tick { block_given? and yield }
      end

      # Proxy server handle
      #
      # @param [Hash]   msg
      # @param [Object] session
      def handle msg, session, &block
        @server.handle msg, session, &block
      end

      # Proxy server global handle
      #
      # @param [Hash]   msg
      # @param [Object] session
      def global_handle msg, session, &block
        @server.global_handle msg, session, &block
      end
    end
  end
end
