# Author:: MinixLi (gmail: MinixLi1986)
# Homepage:: http://citrus.inspawn.com
# Date:: 17 July 2014

require 'citrus/common/service/channel_service'
require 'citrus/components/component'

module Citrus
  # Components
  #
  #
  module Components
    # Channel
    #
    #
    class Channel < Component
      @name = 'channel'

      attr_reader :service

      # Initialize the component
      #
      # @param [Object] app
      # @param [Hash]   args
      def initialize app, args={}
        @service = Common::Service::ChannelService.new app, args

        this = self
        @app.define_singleton_method :channel_service, proc{ this.service }
      end
    end
  end
end
