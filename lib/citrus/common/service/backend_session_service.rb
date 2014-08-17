# Author:: MinixLi (gmail: MinixLi1986)
# Homepage:: http://citrus.inspawn.com
# Date:: 28 July 2014

module Citrus
  # Common
  #
  #
  module Common
    # Service
    #
    #
    module Service
      # BackendSessionService
      #
      #
      class BackendSessionService
        #
        #
        #
        EXPORTED_FIELDS = ['id', 'frontend_id', 'uid', 'settings']

        # Initialize the service
        #
        # @param [Object] app
        def initialize app
          @app = app
        end

        # Create a new backend session
        #
        # @param [Hash] args
        def create args={}
          if args.empty?
            throw Exception.new 'args should not be empty'
          end
          BackendSession.new args, self
        end

        # Get backend session by frontend server id and session id
        #
        # @param [String]  frontend_id
        # @param [Integer] sid
        def get frontend_id, sid, &block
          namespace = 'sys'
          service = 'sessionRemote'
          method = 'getBackendSessionBySid'
          args = [sid]
          rpc_invoke(frontend_id, namespace, service, method,
                  args, &backend_session_cb.bind(nil, block))
        end

        # Get backend sessions by frontend server id and user id
        #
        # @param [String] frontend_id
        # @param [String] uid
        def get_by_uid frontend_id, uid, &block
          namespace = 'sys'
          service = 'sessionRemote'
          method = 'getBackendSessionByUid'
          args = [uid]
          rpc_invoke(server_id, namespace, service, method,
                  args, &backend_session_cb.bind(nil, block))
        end

        # Kick a session by session id
        #
        # @param [String]  frontend_id
        # @param [Integer] sid
        def kick_by_sid frontend_id, sid, &block
          namespace = 'sys'
          service = 'sessionRemote'
          method = 'kickBySid'
          args = [sid]
          rpc_invoke(frontend_id, namespace, service, method, args, &block)
        end

        # Kick sessions by user id
        #
        # @param [String] frontend_id
        # @param [String] uid
        def kick_by_uid frontend_id, uid, &block
          namespace = 'sys'
          service = 'sessionRemote'
          method = 'kickByUid'
          args = [uid]
          rpc_invoke(frontend_id, namespace, service, method, args, &block)
        end

        # Bind the session with the specified user id
        #
        # @param [String]  frontend_id
        # @param [Integer] sid
        # @param [String]  uid
        def bind frontend_id, sid, uid, &block
          namespace = 'sys'
          service = 'sessionRemote'
          method = 'bind'
          args = [sid, uid]
          rpc_invoke(frontend_id, namespace, service, method, args, &block)
        end

        # Unbind the session with the specified user id
        #
        # @param [String]  frontend_id
        # @param [Integer] sid
        # @param [String]  uid
        def unbind frontend_id, sid, uid, &block
          namespace = 'sys'
          service = 'sessionRemote'
          method = 'unbind'
          args = [sid, uid]
          rpc_invoke(frontend_id, namespace, service, method, args, &block)
        end

        # Push the specified customized change to the frontend internal session
        #
        # @param [String]  frontend_id
        # @param [Integer] sid
        # @param [String]  key
        # @param [Hash]    value
        def push frontend_id, sid, key, value, &block
          namespace = 'sys'
          service = 'sessionRemote'
          method = 'push'
          args = [sid, key, value]
          rpc_invoke(frontend_id, namespace, service, method, args, &block)
        end

        # Push all the customized changes to the frontend internal session
        #
        # @param [String]  frontend_id
        # @param [Integer] sid
        # @param [Hash]    settings
        def push_all frontend_id, sid, settings, &block
          namespace = 'sys'
          service = 'sessionRemote'
          method = 'pushAll'
          args = [sid, settings]
          rpc_invoke(frontend_id, namespace, service, method, args, &block)
        end

        private

        # Backend session callback
        #
        # @param [#call]       block
        # @param [Object]      err
        # @param [Hash, Array] sinfos
        #
        # @private
        def backend_session_cb block, err, sinfos
          if err
            block.respond_to? :call and block.call err
            return
          end

          unless sinfos
            block.respond_to? :call and block.call
            return
          end
          sessions = []
          if sinfos.instance_of? Array
            # get_by_uid
            sinfos.each { |sinfo| sessions << create(sinfo) }
          else
            # get
            sessions = create sinfos
          end
          block.respond_to? :call and block.call nil, sessions
        end

        # Rpc invoke
        #
        # @param [String] frontend_id
        # @param [String] namespace
        # @param [String] service
        # @param [String] method
        # @param [Array]  args
        #
        # @private
        def rpc_invoke frontend_id, namespace, service, method, args, &block
          @app.rpc_invoke(frontend_id, {
            :namespace => namespace,
            :service => service,
            :method => method,
            :args => args
          }, &block)
        end

        # BackendSession
        #
        #
        class BackendSession
          # Create a new backend session
          #
          # @param [Hash]   args
          # @param [Object] service
          def initialize args={}, service
            args.each_pair { |key, value|
              instance_eval %Q{ @#{key} = value }
            }
            @session_service = service
          end

          # Bind current session with the user id
          #
          # @param [String] uid
          def bind uid, &block
            @session_service.bind(@frontend_id, @id, uid) { |err|
              @uid = uid unless err
              block_given? and yield err
            }
          end

          # Unbind current session with the user id
          #
          # @param [String] uid
          def unbind uid, &block
            @session_service.unbind(@frontend_id, @id, uid) { |err|
              @uid = nil unless err
              block_given? and yield err
            }
          end

          # Set the key/value into backend session
          #
          # @param [String] key
          # @param [Hash]   value
          def set key, value
            @settings[key] = value
          end

          # Get the value from backend session by key
          #
          # @param [String] key
          def get key
            @settings[key]
          end

          # Push the key/value in backend session to the front internal session
          #
          # @param [String] key
          def push key, &block
            @session_service.push @frontend_id, @id, key, get(key), &block
          end

          # Push all the key/values in backend session to the frontend internal session
          def push_all &block
            @session_service.push_all @frontend_id, @id, @settings, &block
          end

          # Export the key/values for serialization
          def export
            res = {}
            EXPORTED_FIELDS.each { |field|
              instance_eval %Q{ res['#{field}'] = @#{field} }
            }
            res
          end
        end
      end
    end
  end
end
