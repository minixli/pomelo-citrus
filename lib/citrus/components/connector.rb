# Author:: MinixLi (gmail: MinixLi1986)
# Homepage:: http://citrus.inspawn.com
# Date:: 17 July 2014

require 'citrus/components/component'

module Citrus
  # Components
  #
  #
  module Components
    # Connector
    #
    #
    class Connector < Component
      @name = 'connector'

      # Initialize the component
      #
      # @param [Object] app
      # @param [Hash]   args
      def initialize app, args={}
        @app = app
        @connector = get_connector args

        @encode = args[:encode]
        @decode = args[:decode]

        @blacklist_cb = args[:black_list_cb]
        @black_lists = []

        @server = nil
        @session = nil
        @connection = nil
      end

      # Start the component
      def start &block
        @server = @app.components['server']
        @session = @app.components['session']
        @connection = @app.components['connection']

        unless @server
          EM.next_tick {
            block_given? and yield Exception.new 'failed to start connector component for server component not loaded'
          }
          return
        end

        unless @session
          EM.next_tick {
            block_given? and yield Exception.new 'failed to start connector component for session component not loaded'
          }
          return
        end

        EM.next_tick { block_given? and yield }
      end

      # Component lifecycle callback
      def after_start &block
        @connector.start &block
        @connector.on(:connection) { |socket| host_filter socket }
      end

      # Stop the component
      def stop force=false, &block
        if @connector
          @connector.stop force, &block
          @connector = nil
        end
        EM.next_tick { block_given? and yield }
      end

      # Send message to the client
      #
      # @param [Integer] req_id
      # @param [String]  route
      # @param [Hash]    msg
      # @param [Array]   recvs
      # @param [Hash]    args
      def send req_id, route, msg, recvs, args, &block
        if @encode
          # use customized encode
          msg = @encode.call self, req_id, route, msg
        elsif @connector.respond_to? :encode
          # use connector default encode
          msg = @connector.encode req_id, route, msg
        end

        if msg.empty?
          EM.next_tick {
            block_given? and yield Exception.new 'failed to send message for encode result is empty'
          }
          return
        end

        @app.components['push_scheduler'].schedule req_id, route, msg, recvs, args, &block
      end

      private

      # Get the connector
      #
      # @param [Hash] args
      #
      # @private
      def get_connector args={}
        unless connector = args[:connector]
          return get_default_connector args
        end

        port = @app.cur_server[:client_port]
        host = @app.cur_server[:host]

        connector.new port, host, args
      end

      # Get the default connector
      #
      # @param [Hash] args
      #
      # @private
      def get_default_connector args={}
        require 'citrus/connectors/ws_connector'

        port = @app.cur_server[:client_port]
        host = @app.cur_server[:host]

        Connectors::WsConnector.new port, host, args
      end

      # Host filter
      #
      # @param [Object] socket
      #
      # @private
      def host_filter socket
        bind_events socket
      end

      # Bind events
      #
      # @param [Object] socket
      #
      # @private
      def bind_events socket
        if @connection
          @connection.increase_conn_count

          conn_count = @connection.get_statistics_info[:conn_count]
          max_conns = @app.cur_server[:max_conns]

          socket.disconnect; return if conn_count > max_conns
        end

        # Create session for connection
        session = get_session socket
        closed = false

        socket.on(:disconnect) {
          return if closed
          closed = true
          if @connection
            @connection.decrease_conn_count session.uid
          end
        }

        socket.on(:error) {
          return if closed
          closed = true
          if @connection
            @connection.decrease_conn_count session.uid
          end
        }

        socket.on(:message) { |msg|
          if @decode
            msg = @decode.call msg
          elsif @connector.decode
            msg = @connector.decode msg
          end
          # discard invalid message
          return unless msg

          handle_message session, msg
        }
      end

      # Get session
      #
      # @param [Object] socket
      #
      # @private
      def get_session socket
        sid = socket.id
        session = @session.get sid
        return session if session

        session = @session.create sid, @app.server_id, socket

        socket.on(:disconnect) { session.closed }
        socket.on(:error) { session.closed }

        session.on(:closed) { |session, reason|
          @app.emit :close_session, reason
        }

        session.on(:bind) { |uid|
          if @connection
            @connection.add_logined_user(uid, {
              :login_time => Time.now.to_f,
              :uid => uid,
              :address => socket.remote_address[:ip] + ':' + socket.remote_address[:port]
            })
          end

          @app.emit :bind_session, session
        }

        session.on(:unbind) { |uid|
          @app.emit :unbind_session, session
        }

        session
      end

      # Handle message
      #
      # @param [Object] session
      # @param [Hash]   msg
      #
      # @private
      def handle_message session, msg
        type = check_server_type msg['route']
        unless type
          return
        end

        @server.global_handle(msg, session.to_frontend_session) { |err, resp, args|
          unless msg['id']
            return
          end

          resp = {} unless resp
          resp['code'] = 500 if err

          args = { :type => 'response', :user_args => args || {} }
          send(msg['id'], msg['route'], resp, session.id, args) {}
        }
      end

      # Get server type from the request message
      #
      # @param [String] route
      #
      # @private
      def check_server_type route
        return nil unless route
        return nil unless (idx = route.index '.')
        route[0..idx-1]
      end
    end
  end
end
