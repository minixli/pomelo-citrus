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
        # SessionRemote
        #
        #
        class SessionRemote
          # Create a new remote session service
          #
          # @param [Object] app
          def initialize app
            @app = app
          end

          # Bind the session with a user id
          #
          # @param [Integer] sid
          # @param [String]  uid
          def bind sid, uid, &block
            @app.session_service.bind sid, uid, &block
          end

          # Unbind the session with a user id
          #
          # @param [Integer] sid
          # @param [String]  uid
          def unbind sid, uid, &block
            @app.session_service.unbind sid, uid, &block
          end

          # Push the key/value into session
          #
          # @param [Integer] sid
          # @param [String]  key
          # @param [Hash]    value
          def push sid, key, value, &block
            @app.session_service.import sid, key, value, &block
          end

          # Push new value for the existed session
          #
          # @param [Integer] sid
          # @param [Hash]    settings
          def pushAll sid, settings, &block
            @app.session_service.import_all sid, settings, &block
          end

          # Get session information with session id
          #
          # @param [Integer] sid
          def getBackendSessionBySid sid, &block
            session = @app.session_service.get sid
            unless session
              block_given? and yield
              return
            end
            block_given? and yield nil, session.to_frontend_session.export
          end

          # Get all the session information the specified user id
          #
          # @param [String] uid
          def getBackendSessionByUid uid, &block
            sessions = @app.session_service.get_by_uid uid
            unless session
              block_given? and yield
              return
            end

            res = []
            sessions.each { |session|
              res << session.to_frontend_session.export
            }
            block_given? and yield nil, res
          end

          # Kick a session by session id
          #
          # @param [Integer] sid
          def kickBySid sid, &block
            @app.session_service.kick_by_sid sid, &block
          end

          # Kick sessions by user id
          #
          # @param [String] uid
          def kickByUid uid, &block
            @app.session_service.kick uid, &block
          end
        end
      end
    end
  end
end
