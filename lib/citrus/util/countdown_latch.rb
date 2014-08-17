# Author:: MinixLi (gmail: MinixLi1986)
# Homepage:: http://citrus.inspawn.com
# Date:: 16 July 2014

module Citrus
  # Utils
  #
  #
  module Utils
    # CountDownLatch
    #
    #
    class CountDownLatch
      # Create a count down latch
      #
      # @param [Integer] count
      # @param [Hash]    args
      def initialize count, args={}, &block
        @count = count
        @block = block
        if args[:timeout]
          @timer = EM::Timer.new(args[:timeout]) {
            @block.respond_to? :call and @block.call true
          }
        end
      end

      # Called when a task finish count down
      def done
        unless @count > 0
          throw Exception.new 'illegal state'
        end

        @count -= 1
        if @count == 0
          @timer.cancel if @timer
          @block.respond_to? :call and @block.call
        end
      end
    end
  end
end
