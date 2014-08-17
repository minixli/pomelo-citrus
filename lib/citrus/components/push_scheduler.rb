# Author:: MinixLi (gmail: MinixLi1986)
# Homepage:: http://citrus.inspawn.com
# Date:: 17 July 2014

require 'citrus/components/component'
require 'citrus/push_schedulers/direct'

module Citrus
  # Components
  #
  #
  module Components
    # PushScheduler
    #
    #
    class PushScheduler < Component
      @name = 'push_scheduler'

      # Initialize the component
      #
      # @param [Object] app
      # @param [Hash]   args
      def initialize app, args={}
        @app = app
        @scheduler = get_scheduler app, args
      end

      # Component lifecycle callback
      def after_start &block
        if @scheduler.respond_to? :start
          @scheduler.start &block
        else
          EM.next_tick { block.call } if block_given?
        end
      end

      # Component lifecycle callback
      def stop &block
        if @scheduler.respond_to? :stop
          @scheduler.stop &block
        else
          EM.next_tick { block.call } if block_given?
        end
      end

      # Schedule how the message to send
      #
      # @param [Integer] req_id
      # @param [String]  route
      # @param [Hash]    msg
      # @param [Array]   recvs
      # @param [Hash]    args
      def schedule req_id, route, msg, recvs, args, &block
        if @scheculer.respond_to? :schedule
          @scheduler.schedule req_id, route, msg, recvs, args, &block
        else
        end
      end

      private

      # Get scheduler
      #
      # @param [Object] app
      # @param [Hash]   args
      #
      # @private
      def get_scheduler app, args={}
        scheduler = args[:scheduler] || Citrus::PushSchedulers::Direct
        scheduler.new app, args
      end
    end
  end
end
