# Author:: MinixLi (gmail: MinixLi1986)
# Homepage:: http://citrus.inspawn.com
# Date:: 19 July 2014

module Citrus
  # Common
  #
  #
  module Common
    # Service
    #
    #
    module Service
      # SessionService
      #
      #
      class SessionService
        #
        #
        #
        FRONTEND_SESSION_FIELDS = ['id', 'frontend_id', 'uid', 'session_service']
        EXPORTED_SESSION_FIELDS = ['id', 'frontend_id', 'uid', 'settings']

        attr_reader :sessions

        # Initialize the service
        #
        # @param [Hash] args
        def initialize args={}
          @single_session = args[:single_session] || false
          @sessions = {}
          @uid_map = {}
        end

        # Create a new session
        #
        # @param [Integer] sid
        # @param [String]  frontend_id
        # @param [Object]  socket
        def create sid, frontend_id, socket
          session = Session.new sid, frontend_id, socket, self
          @sessions[session.id] = session
          session
        end

        # Bind the session with a user id
        #
        # @param [Integer] sid
        # @param [String]  user_id
        def bind sid, user_id, &block
          session = @sessions[sid]
          unless session
            EM.next_tick {
              block_given? and yield Exception.new 'session does not exist, sid: ' + sid
            }
            return
          end

          if session.uid
            if session.uid == uid
              # already bound with the same uid
              block_given? and yield
              return
            end

            # already bound with another uid
            EM.next_tick {
              block_given? and yield Exception.new 'session has already bound with ' + session.uid
            }
            return
          end

          sessions = @uid_map[uid]

          if sessions && @single_session
            EM.next_tick {
              block_given? and yield Exception.new 'single_session is enabled and session has already bound with uid: ' + uid
            }
            return
          end

          sessions = @uid_map[uid] = [] unless sessions

          sessions.each { |s|
            # session has binded with the uid
            if s.id == session.id
              EM.next_tick { block_given? and yield }
              return
            end
          }
          sessions << session

          session.bind uid

          EM.next_tick { yield } if block_given?
        end

        # Unbind a session with the user id
        #
        # @param [Integer] sid
        # @param [String]  uid
        def unbind sid, uid, &block
          session = @sessions[sid]
          unless session
            EM.next_tick {
              block_given? and yield Exception.new 'session does not exist, sid: ' + sid
            }
            return
          end

          unless session.uid && session.uid == uid
            EM.next_tick {
              block_given? and yield Exception.new 'session has not bind with ' + uid
            }
            return
          end

          sessions = @uid_map[uid]
          if sessions
            sessions.each { |s|
              if s.id == sid
                sessions.delete s
                break
              end
            }

            if sessions.length == 0
              @uid_map.delete uid
            end
          end
          session.unbind uid

          EM.next_tick { yield } if block_given?
        end

        # Get session by id
        #
        # @param [Integer] sid
        def get sid
          @sessions[sid]
        end

        # Get sessions by user id
        #
        # @param [String] uid
        def get_by_uid uid
          @uid_map[uid]
        end

        # Remove session by session id
        #
        # @param [Integer] sid
        def remove sid
          if session = @sessions[sid]
            uid = session.uid
            @sessions.delete session.id

            sessions = @uid_map[uid]
            return unless sessions

            sessions.each { |s|
              if s.id == sid
                sessions.delete s
                @uid_map.delete uid if sessions.length == 0
              end
            }
          end
        end

        # Import the key/value into session
        #
        # @param [Integer] sid
        # @param [String]  key
        # @param [Hash]    value
        def import sid, key, value, &block
          session = @sessions[sid]
          unless session
            block_given? and yield 'session does not exist, sid: ' + sid
            return
          end
          session.set key, value
          block_given? and yield
        end

        # Import new value for the existed session
        #
        # @param [Integer] sid
        # @param [Hash]    settings
        def import_all sid, settings, &block
          session = @sessions[sid]
          unless session
            block_given? and yield 'session does not exist, sid: ' + sid
            return
          end

          settings.each_pair { |key, value| session.set key, value }
          block_given? and yield
        end

        # Kick all the sessions offline under the user id
        #
        # @param [String] uid
        # @param [String] reason
        def kick uid, reason='', &block
          if sessions = get_by_uid(uid)
            # notify client
            sids = []
            sessions.each { |session| sids << session.id }
            sids.each { |sid| @sessions[sid].closed reason }
          end
          EM.next_tick { block_given? and yield }
        end

        # Kick a user offline by session id
        #
        # @param [Integer] sid
        def kick_by_session_id sid, &block
          session = get sid
          session.closed 'kick' if session
          EM.next_tick { block_given? and yield }
        end

        # Get client remote address by session id
        #
        # @param [Integer] sid
        def get_client_address_by_session_id sid
          session = get sid
          return session.socket.remote_addres if session
          return nil
        end

        # Send message to the client by session id
        #
        # @param [Integer] sid
        # @param [Hash]    msg
        def send_message sid, msg
          session = @sessions[sid]

          unless session
            return false
          end

          send session, msg
        end

        # Send message to the client by user id
        #
        # @param [String] uid
        # @param [Hash]   msg
        def send_message_by_uid uid, msg
          sessions = @uid_map[uid]

          unless sessions
            return false
          end

          sessions.each { |session|
            send session, msg
          }
        end

        private

        # Send message to the client that associated with the session
        #
        # @param [Object] session
        # @param [Hash]   msg
        #
        # @private
        def send session, msg
          session.send msg; true
        end

        # Session
        #
        #
        class Session
          include Utils::EventEmitter

          attr_reader :id, :frontend_id, :uid, :settings, :session_service

          # Create a new session
          #
          # @param [Integer] sid
          # @param [String]  frontend_id
          # @param [Object]  socket
          # @param [Object]  service
          def initialize sid, frontend_id, socket, service
            @id = sid
            @frontend_id = frontend_id
            @uid = nil
            @settings = {}

            @socket = socket
            @session_service = service
            @state = :state_inited
          end

          # Export current session as frontend session
          def to_frontend_session
            FrontendSession.new self
          end

          # Bind the session with the uid
          #
          # @param [String] uid
          def bind uid
            @uid = uid
            emit :bind, uid
          end

          # Unbind the session with the uid
          #
          # @param [String] uid
          def unbind uid
            @uid = nil
            emit :unbind, uid
          end

          # Set value for the session
          #
          # @param [String] key
          # @param [Hash] value
          def set key, value
            @settings[key] = value
          end

          # Get value from the session
          #
          # @param [String] key
          def get key
            @settings[key]
          end

          # Send message to the session
          #
          # @param [Hash] msg
          def send msg
            @socket.send msg
          end

          # Send message to the session in batch
          #
          # @param [Array] msgs
          def send_batch msgs
            @socket.send_batch msgs
          end

          # Closed callback for the session which would disconnect client in next tick
          #
          # @param [String] reason
          def closed reason=''
            return if @state == :state_closed

            @state = :state_closed
            @service.remove @id

            emit :closed, to_frontend_session, reason
            @socket.emit :closing, reason

            EM.next_tick { @socket.disconnect }
          end
        end

        # FrontendSession
        #
        #
        class FrontendSession
          include Utils::EventEmitter

          # Create a new frontend session
          #
          # @param [Object] session
          def initialize session
            FRONTEND_SESSION_FIELDS.each { |field|
              instance_eval %Q{ @#{field} = session.#{field} }
            }
            # deep copy for settings
            @settings = session.settings.dup
            @session = session
          end

          # Bind the frontend session with the uid
          #
          # @param [String] uid
          def bind uid, &block
            @session_service.bind(@id, uid) { |err|
              unless err
                @uid = uid
              end
              block_given? and yield err
            }
          end

          # Unbind the session with the uid
          #
          # @param [String] uid
          def unbind uid, &block
            @session_service.unbind(@id, uid) { |err|
              unless err
                @uid = nil
              end
              block_given? and yield err
            }
          end

          # Set value for the frontend session
          #
          # @param [String] key
          # @param [Hash]   value
          def set key, value
            @settings[key] = value
          end

          # Get value from the frontend session
          #
          # @param [String] key
          def get key
            @settings[key]
          end

          # Push value to the internal session
          #
          # @param [String] key
          def push key, &block
            @session_service.import @id, key, get(key), &block
          end

          # Push all the key/value pairs to the internal session
          def push_all &block
            @session_service.import_all @id, @settings, &block
          end

          # Export the key/values for serialization
          def export
            res = {}
            EXPORTED_SESSION_FIELDS.each { |field|
              instance_eval %Q{ res['#{field}'] = @#{field} }
            }
            res
          end
        end
      end
    end
  end
end
