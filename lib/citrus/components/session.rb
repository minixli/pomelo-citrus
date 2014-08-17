# Author:: MinixLi (gmail: MinixLi1986)
# Homepage:: http://citrus.inspawn.com
# Date:: 17 July 2014

require 'citrus/components/component'
require 'citrus/common/service/session_service'

module Citrus
  # Components
  #
  #
  module Components
    # Session
    #
    #
    class Session < Component
      @name = 'session'

      attr_reader :service

      # Initialize the component
      #
      # @param [Object] app
      # @param [Hash]   args
      def initialize app, args={}
        @app = app
        @service = Common::Service::SessionService.new args

        this = self
        @app.define_singleton_method :session_service, proc{ this }
      end

      # Proxy for connection service
      #
      # @param [String] name
      def method_missing name, *args, &block
        @service.send name, *args, &block
      end
    end
  end
end
