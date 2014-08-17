# Author:: MinixLi (gmail: MinixLi1986)
# Homepage:: http://citrus.inspawn.com
# Date:: 25 July 2014

require 'json'
require 'websocket-eventmachine-server'
require 'citrus/connectors/ws_socket'

module Citrus
  # Connectors
  #
  #
  module Connectors
    # WsConnector
    #
    #
    class WsConnector
      include Utils::EventEmitter

      # Create a new websocket connector
      #
      # @param [Integer] port
      # @param [String]  host
      # @param [Hash]    args
      def initialize port, host, args={}
        @port = port
        @host = host
        @args = args

        @heartbeats = args[:heartbeats] || true
        @heartbeat_timeout = args[:heartbeat_timeout] || 0.06
        @heartbeat_interval = args[:heartbeat_interval] || 0.025

        @cur_id = 0
      end

      # Start the connector to listen to the specified port
      def start &block
        begin
          @server = WebSocket::EventMachine::Server.start(:host => @host, :port => @port) { |ws|
            ws.onopen {
              ws_socket = WsSocket.new @cur_id, ws
              @cur_id += 1
              emit :connection, ws_socket
              ws_socket.on(:closing) { |reason|
                ws_socket.send({ 'route' => 'on_kick', 'reason' => reason })
              }
            }
          }
        rescue => err
        end
        EM.next_tick { block_given? and yield }
      end

      # Stop the connector
      #
      # @param [Boolean] force
      def stop force=false, &block
        @server.close
        EM.next_tick { block_given? and yield }
      end

      # Encode message
      #
      # @param [Integer, NilClass] req_id
      # @param [String] route
      # @param [Object] msg
      def encode req_id, route, msg
        if req_id
          compose_response req_id, route, msg
        else
          componse_push route, msg
        end
      end

      # Decode message
      #
      # @param [String] msg
      def decode msg
        begin
          JSON.parse msg
        rescue => err
        end
      end

      private

      # Compose response message
      #
      # @param [Integer] msg_id
      # @param [String]  route
      # @param [Hash]    msg_body
      #
      # @private
      def compose_response msg_id, route, msg_body
        { 'id' => msg_id, 'body' => msg_body }
      end

      # Compose push message
      #
      # @param [String] route
      # @param [Hash]   msg_body
      #
      # @private
      def compose_push route, msg_body
        { 'route' => route, 'body' => msg_body }
      end
    end
  end
end
