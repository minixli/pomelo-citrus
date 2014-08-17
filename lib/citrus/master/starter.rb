# Author:: MinixLi (gmail: MinixLi1986)
# Homepage:: http://citrus.inspawn.com
# Date:: 19 July 2014

module Citrus
  # Master
  #
  #
  module Master
    # Starter
    #
    #
    module Starter
      include Utils

      # Run servers
      def run_servers
        condition = @app.start_id || @app.type
        case condition
        when :master
        when :all
          @app.servers_map.each { |server_id, server|
            run_server server
          }
        else
        end
      end

      # Run server
      #
      # @param [Hash] server
      def run_server server, &block
        if local? server[:host]
          options = []
          options << sprintf('%s', $0)
          options << sprintf('env=%s', @app.env)
          server.each { |key, value|
            options << sprintf('%s=%s', key, value)
          }
          local_run 'ruby', nil, options
        else
        end
      end

      #
      #
      #
      def ssh_run
      end

      #
      #
      #
      def local_run cmd, host, options
        spawn_process cmd, host, options
      end

      #
      #
      #
      def spawn_process cmd, host, options
        child = fork {
          exec cmd + options.inject('') { |res, str| res += ' ' + str }
        }
        EM.watch_process child, Module.new {
          define_method(:process_exited) {
            Process.wait child
          }
        }
      end
    end
  end
end
