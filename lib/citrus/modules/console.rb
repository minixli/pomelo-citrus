# Author:: MinixLi (gmail: MinixLi1986)
# Homepage:: http://citrus.inspawn.com
# Date:: 19 July 2014

require 'citrus/modules/console_module'

module Citrus
  # ConsoleModules
  #
  #
  module ConsoleModules
    # Console
    #
    #
    class Console < ConsoleModule

      @module_id = '__console__'

      # Initialize the module
      #
      # @param [Hash]   args
      # @param [Object] console_service
      def initialize args={}, console_service
      end

      # Monitor handler
      #
      #
      def monitor_handler
      end

      # Master handler
      #
      #
      def master_handler
      end

      # Client handler
      #
      #
      def client_handler
      end
    end
  end
end
