# Author:: MinixLi (gmail: MinixLi1986)
# Homepage:: http://citrus.inspawn.com
# Date:: 17 July 2014

require 'citrus/common/service/connection_service'
require 'citrus/components/component'

module Citrus
  # Components
  #
  #
  module Components
    # Connection
    #
    #
    class Connection < Component
      @name = 'connection'

      DELEGATED_METHODS = [
        :add_logined_user,
        :increase_conn_count,
        :remove_logined_user,
        :decrease_conn_count,
        :get_statistics_info
      ]

      # Initialize the component
      #
      # @param [Object] app
      # @param [Hash]   args
      def initialize app, args={}
        @app = app
        @service = Common::Service::ConnectionService.new app
      end

      # Proxy for connection service
      #
      # @param [String] name
      def method_missing name, *args
        if DELEGATED_METHODS.include? name
          @service.send name, *args
        else
          super
        end
      end
    end
  end
end
