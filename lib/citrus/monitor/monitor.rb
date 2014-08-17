# Author:: MinixLi (gmail: MinixLi1986)
# Homepage:: http://citrus.inspawn.com
# Date:: 20 July 2014

require 'citrus/util/module_util'

module Citrus
  # Monitor
  #
  #
  module Monitor
    # Monitor
    #
    #
    class Monitor
      include Utils::ModuleUtil

      # Create a new monitor
      #
      # @param [Object] app
      # @param [Hash]   args
      def initialize app, args={}
        @app = app
        @master = false
        @master_info = @app.master
        @server_info = @app.cur_server
        @modules = []
        @close_watcher = args[:close_watcher]
        @console_service = CitrusAdmin::ConsoleService.create_monitor_console({
          :env => @app.env,
          :host => @master_info[:host],
          :port => @master_info[:port],
          :server_id => @server_info[:server_id],
          :server_type => @app.server_type,
          :server_info => @server_info,
          :auth_server => nil
        })
      end

      # Start master
      def start &block
        register_default_modules
        load_modules
        @console_service.start { |err|
          if err
            block_given? and yield err
            return
          end
          start_modules { |err|
            block_given? and yield err
            return
          }
        }
      end

      # Stop master
      def stop &block
      end
    end
  end
end
