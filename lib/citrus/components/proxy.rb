# Author:: MinixLi (gmail: MinixLi1986)
# Homepage:: http://citrus.inspawn.com
# Date:: 20 July 2014

require 'digest/crc32'
require 'citrus/components/component'
require 'citrus/util/path_util'

module Citrus
  # Components
  #
  #
  module Components
    # Proxy
    #
    #
    class Proxy < Component
      @name = 'proxy'

      include Utils::PathUtil

      # Initialize the component
      #
      # @param [Object] app
      # @param [Hash]   args
      def initialize app, args={}
        args[:buffer_msg] = args[:buffer_msg] || false
        args[:interval]  = args[:interval] || 0.03

        args[:router] = gen_router
        args[:context] = app
        args[:route_context] = app

        @args = args
        @client = CitrusRpc::RpcClient::Client.new @args

        @app = app
        @app.on(:add_servers) { |servers| add_servers servers }
        @app.on(:remove_servers) { |ids| remove_servers ids }
        @app.on(:replace_servers) { |servers| replace_servers servers }
      end

      # Start the component
      def start &block
        unless @app.rpc_befores.empty?
          @client.before @app.rpc_befores
        end

        unless @app.rpc_afters.empty?
          @client.after @app.rpc_afters
        end

        if @app.rpc_error_handler
          @client.set_error_handler @app.rpc_error_handler
        end

        EM.next_tick { block_given? and yield }
      end

      # Component lifecycle callback
      def after_start &block
        @app.rpc = @client.proxies.user
        @app.sysrpc = @client.proxies.sys

        @app.define_singleton_method :rpc_invoke, proc{ |*args, &block|
          @client.rpc_invoke *args, &block
        }

        @client.start &block
      end

      # Add remote servers
      #
      # @param [Array] servers
      def add_servers servers
        return unless servers
        return if servers.empty

        gen_proxies servers

        @client.add_servers servers
      end

      # Remove remote servers
      #
      # @param [Array] ids
      def remove_servers ids
        @client.remove_servers ids
      end

      # Replace remote servers
      #
      # @param [Array] servers
      def replace_servers servers
        return unless servers
        return if servers.empty

        @client.proxies = {}
        gen_proxies servers

        @client.replace_servers servers
      end

      # Proxy for rpc client's rpc_invoke
      #
      # @param [String] server_id
      # @param [Hash]   msg
      def rpc_invoke server_id, msg, &block
        @client.rpc_invoke server_id, msg, &block
      end

      private

      # Generate proxies for the server infos
      #
      # @param [Array] sinfos
      #
      # @private
      def gen_proxies sinfos
        sinfos.each { |sinfo|
          @client.add_proxies get_proxy_records(sinfo) unless has_proxy? sinfo
        }
      end

      # Check whether a proxy has been generated
      #
      # @param [Hash] sinfo
      #
      # @private
      def has_proxy? sinfo
        @client.proxies.sys && @client.proxies.sys.respond_to? sinfo[:server_type]
      end

      # Get proxy path for rpc client
      #
      # @param [Hash] sinfo
      #
      # @private
      def get_proxy_records sinfo
        records = []

        role = @app.frontend? sinfo ? :frontend : :backend
        server_type = sinfo[:server_type]

        record = get_sys_remote_path role
        records << remote_path_record('sys', server_type, record) if record

        record = get_user_remote_path @app.base, server_type
        records << remote_path_record('user', server_type, record) if record

        records
      end

      # Generate router
      #
      # @private
      def gen_router
        Proc.new { |session, msg, &block|
          routers = @app.routers
          unless routers
            default_router session, msg, &block
            return
          end

          type = msg['server_type']
          router = routers[type] || routers['default']

          if router
            router.call session, msg, &block
          else
            default_router session, msg, &block
          end
        }
      end

      # Default router
      #
      # @param [Object] session
      # @param [Hash]   msg
      #
      # @private
      def default_router session, msg, &block
        list = @app.get_servers_by_type msg['server_type']
        unless list && !list.empty?
          block_given? and yield Exception.new 'can not find server info for type: ' + msg['server_type']
          return
        end

        uid = session ? (session.uid || '') : ''
        idx = (Digest::CRC32.hexdigest uid).to_i % list.length
        block_given? and yield nil, list[idx][:server_id]
      end
    end
  end
end
