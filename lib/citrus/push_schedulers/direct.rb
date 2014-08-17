# Author:: MinixLi (gmail: MinixLi1986)
# Homepage:: http://citrus.inspawn.com
# Date:: 16 July 2014

module Citrus
  # PushSchedulers
  #
  #
  module PushSchedulers
    # Direct
    #
    #
    class Direct
      # Initialize the component
      #
      # @param [Object] app
      # @param [Hash]   args
      def initialize app, args
        @app = app
      end

      # Schedule
      #
      # @param [Integer] req_id
      # @param [String]  route
      # @param [Hash]    msg
      # @param [Array]   recvs
      # @param [Hash]    args
      def schedule req_id, route, msg, recvs, args, &block
        if args[:type] == 'broadcast'
          do_broadcast msg, args[:user_args]
        else
          do_batch_push msg, recvs
        end

        EM.next_tick { block.call } if block_given?
      end

      private

      # Do broadcast
      #
      # @param [Hash]  msg
      # @param [Hash]  args
      #
      # @private
      def do_broadcast msg, args={}
        channel_service = @app.channel_service
        session_service = @app.session_service

        if args[:binded]
          session_service.sessions.each { |session|
            session_service.send_message_by_uid session.uid, msg
          }
        else
          session_service.sessions.each { |session|
            session_service.send_message session.id, msg
          }
        end
      end

      # Do batch push
      #
      # @param [Hash]  msg
      # @param [Array] recvs
      #
      # @private
      def do_batch_push msg, recvs
        session_service = @app.session_service
        recvs.each { |recv|
          session_service.send_message recv, msg
        }
      end
    end
  end
end