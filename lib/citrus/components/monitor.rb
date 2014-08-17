# Author:: MinixLi (gmail: MinixLi1986)
# Homepage:: http://citrus.inspawn.com
# Date:: 17 July 2014

require 'citrus/components/component'
require 'citrus/monitor/monitor'

module Citrus
  # Components
  #
  #
  module Components
    # Monitor
    #
    #
    class Monitor < Component
      @name = 'monitor'

      # Initialize the component
      #
      # @param [Object] app
      # @param [Hash]   args
      def initialize app, args={}
        @monitor = Citrus::Monitor::Monitor.new app, args
      end

      # Start the component
      def start &block
        @monitor.start &block
      end

      # Stop the component
      #
      # @param [Boolean] force
      def stop force=false, &block
        @monitor.stop &block
      end

      # Reconnect the master
      #
      # @param [Hash] master_info
      def reconnect master_info
        @monitor.reconnect master_info
      end
    end
  end
end

