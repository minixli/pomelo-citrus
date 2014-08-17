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
      # HandlerService
      #
      #
      class HandlerService
        # Initialize the service
        #
        # @param [Object] app
        # @param [Hash]   handlers
        def initialize app, handlers={}
          @app = app
          @handlers = handlers
        end

        # Handle message from the client
        #
        # @param [Hash]   route_record
        # @param [Hash]   msg
        # @param [Object] session
        def handle route_record, msg, session, &block
          handler = get_handler route_record
          unless handler
            block_given? and yield Exception.new 'failed to find the handler'
            return
          end
          handler.send(route_record['method'], msg, session) { |err, resp, args|
            block_given? and yield err, resp, args
          }
        end

        private

        # Get handler by route record
        #
        # @param [Hash] route_record
        #
        # @private
        def get_handler route_record
          handler = @handlers[route_record['handler']]
          unless handler
            return nil
          end
          unless handler.respond_to? route_record['method']
            return nil
          end
          handler
        end
      end
    end
  end
end
