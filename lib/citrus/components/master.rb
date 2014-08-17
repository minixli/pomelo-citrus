# Author:: MinixLi (gmail: MinixLi1986)
# Homepage:: http://citrus.inspawn.com
# Date:: 17 July 2014

require 'citrus/components/component'
require 'citrus/master/master'

module Citrus
  # Components
  #
  #
  module Components
    # Master
    #
    #
    class Master < Component
      @name = 'master'

      # Initialize the component
      #
      # @param [Object] app
      # @param [Hash]   args
      def initialize app, args={}
        @master = Citrus::Master::Master.new app, args
      end

      # Start the component
      def start &block
        @master.start &block
      end

      # Stop the component
      #
      # @param [Boolean] force
      def stop force=false, &block
        @master.stop &block
      end
    end
  end
end
