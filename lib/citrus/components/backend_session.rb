# Author:: MinixLi (gmail: MinixLi1986)
# Homepage:: http://citrus.inspawn.com
# Date:: 17 July 2014

require 'citrus/common/service/backend_session_service'
require 'citrus/components/component'

module Citrus
  # Components
  #
  #
  module Components
    # BackendSession
    #
    #
    class BackendSession < Component
      @name = 'backend_session'

      attr_reader :service

      # Initialize the component
      #
      # @param [Object] app
      def initialize app
        @service = Common::Service::BackendSessionService.new app

        this = self
        @app.define_singleton_method :backend_session_service, proc{ this.service }
      end
    end
  end
end
