# Author:: MinixLi (gmail: MinixLi1986)
# Homepage:: http://citrus.inspawn.com
# Date:: 21 July 2014

module Citrus
  # ConsoleModules
  #
  #
  module ConsoleModules
    # ConsoleModule
    #
    #
    class ConsoleModule
      #
      #
      #
      def self.inherited subclass
        class << subclass
          attr_reader :module_id
        end
      end

      attr_reader :type, :delay, :interval

      #
      #
      #
      def initialize
        @type = ''
        @delay = 0
        @interval = 0
      end
    end
  end
end
