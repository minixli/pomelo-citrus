# Author:: MinixLi (gmail: MinixLi1986)
# Homepage:: http://citrus.inspawn.com
# Date:: 17 July 2014

require 'citrus/components/component'
require 'citrus/util/path_util'

module Citrus
  # Components
  #
  #
  module Components
    # Remote
    #
    #
    class Remote < Component
      @name = 'remote'

      include Utils::PathUtil

      # Initialize the component
      #
      # @param [Object] app
      # @param [Hash]   args
      def initialize app, args={}
        args[:buffer_msg] = args[:buffer_msg] || false
        args[:interval]  = args[:interval] || 0.03
        @app = app
        @args = args
      end

      # Start the component
      def start &block
        @args[:port] = @app.cur_server[:port]
        @args[:paths] = get_remote_paths
        @args[:context] = @app

        @remote = CitrusRpc::RpcServer::Server.new @args
        @remote.start

        EM.next_tick { block_given? and yield }
      end

      # Stop the component
      #
      # @param [Boolean] force
      def stop force=false, &block
        @remote.stop force
        EM.next_tick { block_given? and yield }
      end

      private

      # Get remote paths
      def get_remote_paths
        paths = []

        role = @app.frontend? sinfo ? :frontend : :backend
        server_type = sinfo[:server_type]

        sys_path = get_sys_remote_path role
        paths << remote_path_record('sys', server_type, sys_path) if sys_path

        user_path = get_user_remote_path @app.base, server_type
        paths << remote_path_record('user', server_type, user_path) if user_path

        paths
      end
    end
  end
end
