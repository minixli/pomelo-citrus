# Author:: MinixLi (gmail: MinixLi1986)
# Homepage:: http://citrus.inspawn.com
# Date:: 16 July 2014

require 'citrus/util/constants'

module Citrus
  # Utils
  #
  #
  module Utils
    # AppUtil
    #
    #
    module AppUtil
      # Initialize application configuration
      def default_configuration
        args = parse_args
        setup_env args
        load_master
        load_servers
        process_args args
        config_logger
        load_lifecycle
      end

      # Parse command line arguments
      def parse_args
        args_map = {:main => $0}
        ARGV.each { |arg|
          sep = arg.index('=')

          key = arg[0..sep-1].to_sym
          val = arg[sep+1..-1]

          if val == 'true'
            val = true
          end
          if val == 'false'
            val = false
          end
          args_map[key] = val
        }
        return args_map
      end

      # Setup enviroment
      #
      # @param [Hash] args
      def setup_env args={}
        @env = args[:env] ? args[:env].to_sym : :development
      end

      #  Load master info from config/master.json
      def load_master
        @master = load_config_file Constants::Filepath::MASTER
      end

      # Load server info from config/servers.json
      def load_servers
        servers = load_config_file Constants::Filepath::SERVER
        servers.each { |server_type, servers|
          servers.each { |server|
            server[:server_type] = server_type.to_s
            @servers_map[server[:server_id]] = server
          }
        }
      end

      # Process server start command
      #
      # @param [Hash] args
      def process_args args={}
        @type = args[:type] ? args[:type].to_sym : :all
        @server_type = args[:server_type] ? args[:server_type] : 'master'
        @server_id = args[:server_id] || @master[:server_id]
        @start_id = args[:start_id]

        if @server_type == 'master'
          @cur_server = @master
        else
          @cur_server = args
        end
      end

      # Configure logger
      def config_logger
      end

      # Load life cycle
      def load_lifecycle
      end

      # Load config file
      #
      # @param [String] filename
      def load_config_file filename
        origin_path = File.join @base, filename
        present_path = File.join @base, Constants::Filepath::CONFIG_DIR, @env.to_s, File.basename(filename)
        unless File.exists?(origin_path) && file_path = origin_path
          unless File.exists? present_path && file_path = present_path
          end
        end
        config = {}
        instance_eval %Q{
          config = #{File.read file_path}
        }
        if file_path == origin_path && config[@env]
          config = config[@env]
        end
        return config
      end

      # Load default components for application
      def load_default_components
        if @server_type == 'master'
          load Components::Master
        else
          load Components::Proxy
          load Components::Remote if @cur_server[:port]
          load Components::Connection if frontend?
          load Components::Connector if frontend?
          load Components::Session if frontend?
          load Components::PushScheduler if frontend?
          load Components::BackendSession
          load Components::Channel
          load Components::Server
        end
        load Components::Monitor
      end

      # Load component
      #
      # @param [Class] component
      def load component
        name = component.name
        instance_eval %Q{
          @components[name] = #{component}.new self, @settings[:#{name}_config] || {}
        }
      end

      # Stop components
      #
      # @param [Array]   components
      # @param [Integer] index
      # @param [Boolean] force
      def stop_components components, index, force, &block
      end

      # Apply command to loaded components
      #
      # @param [Array]  components
      # @param [Symbol] method
      def opt_components components, method, &block
        opt_component nil, components, method, 0, &block
      end

      # Apply command to loaded component
      #
      # @param [Object]  err
      # @param [Array]   components
      # @param [Symbol]  method
      # @param [Integer] index
      def opt_component err, components, method, index, &block
        if err || index >= components.length
          block_given? and yield err
          return
        end
        component = components[index]
        if component && component.respond_to?(method)
          component.send method, &proc{ |err|
            opt_component err, components, method, (index + 1), &block
          }
        else
          opt_component err, components, method, (index + 1), &block
        end
      end

      # Register console module
      #
      # @param [Class] module_klass
      # @param [Hash]  args
      def register module_klass, args={}
        module_id = module_klass.module_id
        @modules_registered[module_id] = {
          :module_id => module_id,
          :module_klass => module_klass,
          :args => args
        }
      end

      # Check whether a string is contained in the settings
      #
      # @param [String] str
      # @param [String] settings
      def contains str, settings
        return false unless settings.instance_of? String
        return false if settings.empty?
        settings.split('|').inject(false) { |r, t| true if str == t }
      end
    end
  end
end
