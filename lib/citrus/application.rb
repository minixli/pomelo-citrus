# Author:: MinixLi (gmail: MinixLi1986)
# Homepage:: http://citrus.inspawn.com
# Date:: 16 July 2014

require 'citrus/util/app_util'

module Citrus
  # Application
  #
  #
  class Application
    include Utils::AppUtil
    include Utils::EventEmitter

    attr_reader :env, :base, :type, :start_id
    attr_reader :cur_server, :server_id, :server_type
    attr_reader :master, :servers_map
    attr_reader :components, :modules_registered

    # Initialize the application
    #
    # @param [Hash] args Option
    def initialize args={}
      @env = nil
      @type = nil
      @start_id = nil

      @base = args[:base] || Dir.pwd
      @settings = {}

      # current server info
      @cur_server = nil
      @server_id = nil
      @server_type = nil
      @start_time = nil

      # global server info
      @master = nil
      @servers = {}
      @servers_map = {}
      @server_types = []
      @server_type_maps = {}

      # lifecycle callbacks
      @lifecycle_cbs = {}

      @components = {}
      @modules_registered = {}

      default_configuration

      @state = :state_inited

      # singleton pattern
      eval %Q{
        class ::Citrus::Application
          private_class_method :new
        end
      }
    end

    # Start the application
    def start &block
      @start_time = Time.now.to_f
      if @state != :state_inited
        block_given? and yield Exception.new 'application double start'
        return
      end

      if @start_id
        if @start_id != 'master'
          Starter.run_servers self
          return
        end
      else
        if @type && @type != :all && @type != :master
          Starter.run_servers self
          return
        end
      end

      load_default_components

      if before_cb = @lifecycle_cbs[:before_startup]
        before_cb.call self, &proc{
          start_up &block
        }
      else
        start_up &block
      end
    end

    # Start up
    def start_up &block
      opt_components(@components.values, :start) { |err|
        @state = :state_started
        if err
          block_given? and yield err
        else
          after_start &block
        end
      }
    end

    # Lifecycle callback for after start
    def after_start &block
      if @state != :state_started
        block_given? and yield RuntimeError.new 'application is not running now'
        return
      end

      opt_components(@components.values, :after_start) { |err|
        if after_cb = @lifecycle_cbs[:after_start]
          after_cb.call self, &proc{
            block_given? and yield err
          }
        else
          block_given? and yield err
        end
      }
      puts used_time = Time.now.to_f - @start_time
    end

    # Stop components
    #
    #
    def stop force=false
    end

    # Assign `setting` to `value`
    #
    # @param [Symbol] setting
    # @param [Object] value
    def set setting, value
      @settings[setting] = value
      return self
    end

    # Get property from setting
    #
    # @param [Symbol] setting
    def get setting
      @settings[setting]
    end

    # Configure callback for the specified env and server type
    def configure *args, &block
      args.length > 0 ? env = args[0].to_s : env = 'all'
      args.length > 1 ? server_type = args[1].to_s : server_type = 'all'
      if env == 'all' || contains(@env.to_s, env)
        if server_type == 'all' || contains(@server_type, server_type)
          instance_eval &block if block
        end
      end
      return self
    end

    # Get server infos by server type
    #
    # @param [String] type
    def get_servers_by_type type
      @server_type_maps[type]
    end

    # Check whether a server is a frontend
    #
    # @param [Object] server
    def frontend? server=nil
      server ? server[:frontend] == true : @cur_server[:frontend] == true
    end

    # Check whether a server is a backend
    #
    # @param [Object] server
    def backend? server=nil
      not frontend? server
    end

    # Check whether a server is a master
    def master?
      @server_type == 'master'
    end

    # Add new servers at runtime
    #
    # @param [Array] sinfos
    def add_servers sinfos
      return unless sinfos && !sinfos.empty?
      sinfos.each { |sinfo|
        # update global server map
        @servers[sinfo[:server_id]] = sinfo

        # update global server type map
        slist = @server_type_maps[sinfo[:server_type]] ||= []
        replace_server slist, sinfo

        # update global server type list
        if !@server_types.member? sinfo[:server_type]
          @server_types << sinfo[:server_type]
        end
      }
      emit 'add_servers', sinfos
    end

    # Remove servers at runtime
    #
    # @param [Array] server_ids
    def remove_servers server_ids
    end

    # Replace servers at runtime
    #
    # @param [Array] sinfos
    def replace_servers sinfos
    end

    # Remove server at runtime
    #
    # @param [String] server_id
    def remove_server server_id
    end

    # Replace server at runtime
    #
    # @param [Array] slist
    # @param [Hash]  server_info
    def replace_server slist, sinfo
      slist.each_with_index { |s, index|
        if s[:server_id] == sinfo[:server_id]
          slist[index] = sinfo 
          return
        end
      }
      slist << sinfo
    end
  end
end
