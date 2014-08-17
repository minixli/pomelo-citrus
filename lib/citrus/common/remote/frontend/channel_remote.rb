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
      # Frontend
      #
      #
      module Frontend
        # ChannelRemote
        #
        #
        class ChannelRemote
          # Create a new remote channel service
          #
          # @param [Object] app
          def initialize app
            @app = app
          end

          # Push message to client by uids
          #
          # @param [String] route
          # @param [Hash]   msg
          # @param [Array]  uids
          # @param [Hash]   args
          def pushMessage route, msg, uids, args, &block
            if msg.empty?
              block_given? and yield Exception.new 'can not send empty message'
              return
            end

            connector = @app.components['connector']

            session_service = @app.session_service
            sids = []; fails = []
            uids.each { |uid|
              sessions = session_service.get_by_uid uid
              if sessions
                sessions.each { |session|
                  sids << session.id
                }
              else
                fails << uid
              end
            }
            connector.send(nil, route, msg, sids, args) { |err|
              block_given? and yield err, fails
            }
          end

          # Broadcast to all the clients connected with current frontend server
          #
          # @param [String] route
          # @param [Hash]   msg
          # @param [Hash]   args
          def broadcast route, msg, args, &block
            connector = @app.components['connector']
            connector.send nil, route, msg, nil, args, &block
          end
        end
      end
    end
  end
end
