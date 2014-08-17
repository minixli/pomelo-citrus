# Author:: MinixLi (gmail: MinixLi1986)
# Homepage:: http://citrus.inspawn.com
# Date:: 25 July 2014

require 'json'

module Citrus
  # Connectors
  #
  #
  module Connectors
    # WsSocket
    #
    #
    class WsSocket
      include Utils::EventEmitter

      attr_reader :id, :remote_address

      # Create a new ws socket
      #
      # @param [Integer] id
      # @param [Object]  ws
      def initialize id, ws
        @id = id
        @ws = ws

        port, ip = Socket.unpack_sockaddr_in @ws.get_peername
        @remote_address = {
          :port => port,
          :ip => ip
        }

        @ws.onclose { emit :disconnect }
        @ws.onerror { |err| emit :error }
        @ws.onmessage { |msg, type| emit :message, msg }

        @state = :state_inited
      end

      # Send message to the client
      #
      # @param [Hash] msg
      def send msg
        return unless @state == :state_inited
        @ws.send msg.to_json
      end

      # Disconnect the client
      def disconnect
        return if @state == :state_closed
        @state = :state_closed
        @ws.close
      end

      # Batch version for send
      #
      # @param [Array] msgs
      def send_batch msgs
        @ws.send encode_batch(msgs)
      end

      private

      # Encode batch messages
      #
      # @param [Array] msgs
      #
      # @private
      def encode_batch msgs
        msgs.to_json
      end
    end
  end
end
