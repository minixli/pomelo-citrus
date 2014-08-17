# Author:: MinixLi (gmail: MinixLi1986)
# Homepage:: http://citrus.inspawn.com
# Date:: 29 July 2014

module Citrus
  # Common
  #
  #
  module Common
    # Service
    #
    #
    module Service
      # FilterService
      #
      #
      class FilterService
        # Initialize the service
        def initialize
          @befores = []
          @afters = []
        end

        # Add before filter into the filter chain
        #
        # @param [#call] filter
        def before filter
          @befores << filter
        end

        # Add after filter into the filter chain
        #
        # @param [#call] filter
        def after filter
          @afters.unshift filter
        end

        # Do the before filter chain
        #
        # @param [Hash]   msg
        # @param [Object] session
        def before_filter msg, session, &block
          index = 0

          next_p = Proc.new { |err, resp, args|
            if err || index >= @befores.length
              block_given? and yield err, resp, args
              return
            end

            handler = @befores[index]
            index += 1

            if handler.respond_to? :call
              handler.call msg, session, &next_p
            else
              next_p.call Exception.new 'invalid before filter'
            end
          }
          next_p.call
        end

        # Do the after filter chain
        #
        # @param [Object] err
        # @param [Hash]   msg
        # @param [Object] session
        # @param [Hash]   resp
        def after_filter err, msg, session, resp, &block
          index = 0

          next_p = Proc.new { |err|
            if index >= @afters.length
              block_given? and yield err
              return
            end

            handler = @afters[index]
            index += 1

            if handler.respond_to? :call
              handler.call err, msg, session, resp, &next_p
            else
              next_p.call Exception.new 'invalid after filter'
            end
          }
          next_p.call err
        end
      end
    end
  end
end
