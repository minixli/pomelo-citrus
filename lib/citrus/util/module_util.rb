# Author:: MinixLi (gmail: MinixLi1986)
# Homepage:: http://citrus.inspawn.com
# Date:: 18 July 2014

require 'citrus/modules/console'
require 'citrus/modules/master_watcher'
require 'citrus/modules/monitor_watcher'

module Citrus
  # Utils
  #
  #
  module Utils
    # ModuleUtil
    #
    #
    module ModuleUtil
      # Register default console modules
      def register_default_modules
        unless @close_watcher
          if @master
            @app.register ConsoleModules::MasterWatcher, {:app => @app}
          else
            @app.register ConsoleModules::MonitorWatcher, {:app => @app}
          end
        end
        @app.register ConsoleModules::Console, {:app => @app}
      end

      # Load console modules
      def load_modules
        @app.modules_registered.each { |module_id, module_registered|
          klass = module_registered[:module_klass]
          args = module_registered[:args]
          module_entity = klass.new args, @console_service
          @console_service.register module_registered[:module_id], module_entity
          @modules << module_entity
        }
      end

      # Start console modules
      def start_modules &block
        start_module nil, @modules, 0, &block
      end

      # Start console module
      #
      # @param [Object]  err
      # @param [Array]   modules
      # @param [Integer] index
      def start_module err, modules, index, &block
        if err || index >= modules.length
          block_given? and yield err
          return
        end

        console_module = modules[index]
        if console_module && console_module.respond_to?(:start)
          console_module.start { |err|
            start_module err, modules, (index + 1), &block
          }
        else
          start_module err, modules, (index + 1), &block
        end
      end
    end
  end
end
