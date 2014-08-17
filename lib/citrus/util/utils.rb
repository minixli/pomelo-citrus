# Author:: MinixLi (gmail: MinixLi1986)
# Homepage:: http://citrus.inspawn.com
# Date:: 16 July 2014

module Citrus
  # Utils
  #
  #
  module Utils
    # Check whether a host is a local adress
    #
    # @param [String] host
    def local? host
      return true
    end

    # EventEmitter
    #
    #
    module EventEmitter
      # Register event
      #
      # @param [String] event
      def on event, &block
        @on_blocks ||= {}
        @on_blocks[event] = block
      end

      # Register event once
      #
      # @param [String] event
      def once event, &block
        @once_blocks ||= {}
        @once_blocks[event] = block
      end

      # Emit event
      def emit *args
        event = args.shift
        if @once_blocks && block = @once_blocks[event]
          @once_blocks.delete event
        elsif !@on_blocks || !block = @on_blocks[event]
          return
        end
        block.call *args
      end
    end
  end
end
