# Author:: MinixLi (gmail: MinixLi1986)
# Homepage:: http://citrus.inspawn.com
# Date:: 18 July 2014

require 'citrus/master/starter'
require 'citrus/util/module_util'

module Citrus
  # Master
  #
  #
  module Master
    # Master
    #
    #
    class Master
      include Starter
      include Utils::ModuleUtil

      # Create a new master
      #
      # @param [Object] app
      # @param [Hash]   args
      def initialize app, args={}
        @app = app
        @master = true
        @master_info = app.master
        @modules = []
        @close_watcher = args[:close_watcher]
        @console_service = CitrusAdmin::ConsoleService.create_master_console(
          args.merge({
            :env => app.env,
            :port => @master_info[:port]
          })
        )
      end

      # Start master
      def start &block
        register_default_modules
        load_modules
        @console_service.start { |err|
          exit if err
          start_modules { |err|
            if err
              block_given? and yield err
              return
            end
            run_servers
            block_given? and yield
          }
        }
      end

      # Stop master
      def stop &block
      end
    end
  end
end
