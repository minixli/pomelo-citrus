# Author:: MinixLi (gmail: MinixLi1986)
# Homepage:: http://citrus.inspawn.com
# Date:: 24 July 2014

module Citrus
  # Common
  #
  #
  module Common
    # Remote
    #
    #
    module Remote
      # Backend
      #
      #
      module Backend
        # MsgRemote
        #
        #
        class MsgRemote
          # Create a new remote message service
          #
          # @param [Object] app
          def initialize app
            @app = app
          end

          # Forward message from frontend server
          #
          # @param [Hash]   msg
          # @param [Object] session
          def forwardMessage msg, session, &block
            server = @app.components['server']
            session_service = @app.components['backend_session'].service

            unless server
              block_given? and yield Exception.new 'server component not enabled'
              return
            end

            unless session_service
              block_given? and yield Exception.new 'backend session component not enabled'
              return
            end

            backend_session = session_service.create session

            server.handle(msg, backend_session) { |err, resp, args|
              block_given? and yield err, resp, args
            }
          end
        end
      end
    end
  end
end
