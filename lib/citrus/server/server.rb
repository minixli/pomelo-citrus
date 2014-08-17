# Author:: MinixLi (gmail: MinixLi1986)
# Homepage:: http://citrus.inspawn.com
# Date:: 29 July 2014

require 'citrus/common/service/filter_service'
require 'citrus/common/service/handler_service'
require 'citrus/util/path_util'

module Citrus
  # Server
  #
  #
  module Server
    # Server
    #
    #
    class Server
      include CitrusLoader
      include Utils::PathUtil

      # Create a new server
      #
      # @param [Object] app
      def initialize app
        @app = app

        @global_filter_service = nil
        @filter_service = nil
        @handler_service = nil

        @crons = []
        @jobs = {}
        @state = :state_inited

        @app.on(:add_crons) { |crons| add_crons crons }
        @app.on(:remove_crons) { |crons| remove_crons crons }
      end

      # Start the server
      def start
        return unless @state == :state_inited

        @global_filter_service = init_filter true
        @filter_service = init_filter false
        @handler_service = init_handler

        @state = :state_started
      end

      # After the sever start
      def after_start
      end

      # Stop the server
      def stop
        @state = :state_stoped
      end

      # Global handler
      #
      # @param [Hash]   msg
      # @param [Object] session
      def global_handle msg, session, &block
        unless @state == :state_started
          block_given? and yield Exception.new 'server not started'
          return
        end

        route_record = parse_route msg['route']
        unless route_record
          block_given? and yield Exception.new 'meet unknown route message'
          return
        end

        dispatch = Proc.new { |err, resp, args|
          if err
            handle_error(true, err, msg, session, resp, args) { |err, resp, args|
              response true, err, msg, session, resp, args, &block
            }
            return
          end

          unless @app.server_type == route_record['server_type']
            do_forward(msg, session, route_record) { |err, resp, args|
              response true, err, msg, session, resp, args, &block
            }
          else
            do_handle(msg, session, route_record) { |err, resp, args|
              response true, err, msg, session, resp, args, &block
            }
          end
        }
        before_filter true, msg, session, &dispatch
      end

      # Handle request
      #
      # @param [Hash]   msg
      # @param [Object] session
      def handle msg, session, &block
        unless @state == :state_started
          block_given? and yield Exception.new 'server not started'
          return
        end

        route_record = parse_route msg['route']
        do_handle msg, session, route_record, &block
      end

      # Add crons at runtime
      #
      # @param [Array] crons
      def add_crons crons
      end

      # Remove crons at runtime
      #
      # @param [Array] crons
      def remove_crons crons
      end

      private

      # Init filter service
      #
      # @param [Boolean] is_global
      #
      # @private
      def init_filter is_global
        service = Common::Service::FilterService.new

        if is_global
          befores = @app.global_befores
          afters = @app.global_afters
        else
          befores = @app.befores
          afters = @app.afters
        end

        befores.each { |before| service.before before }
        afters.each { |after| service.after after }

        service
      end

      # Init handler service
      #
      # @private
      def init_handler
        Common::Service::HandlerService.new @app, load_handlers
      end

      # Load handlers from current application
      #
      # @private
      def load_handlers
        handlers = {}
        path = get_handler_path @app.base, @app.server_type
        if path
          klasses = load_app_handler path
          klasses.each { |klass|
            handler = klass.name
            handler[0] = handler[0].downcase
            handlers[handler] = klass.new @app
          }
        end
        handlers
      end

      # Fire before filter chain if any
      #
      # @param [Boolean] is_global
      # @param [Hash]    msg
      # @param [Object]  session
      #
      # @private
      def before_filter is_global, msg, session, &block
        if is_global
          fm = @global_filter_service
        else
          fm = @filter_service
        end
        if fm
          fm.before_filter msg, session, &block
        else
          block_given? and yield
        end
      end

      # Fire after filter chain if any
      #
      # @param [Boolean] is_global
      # @param [Object]  err
      # @param [Hash]    msg
      # @param [Object]  session
      # @param [Hash]    resp
      # @param [Hash]    args
      #
      # @private
      def after_filter is_global, err, msg, session, resp, args, &block
        if is_global
          fm = @global_filter_service
        else
          fm = @filter_service
        end
        if fm
          if is_global
            fm.after_filter(err, msg, session, resp) {}
          else
            fm.after_filter(err, msg, session, resp) {
              block_given? and yield err, resp, args
            }
          end
        end
      end

      # Pass err to the global error handler if specified
      #
      # @param [Boolean] is_global
      # @param [Object]  err
      # @param [Hash]    msg
      # @param [Object]  session
      # @param [Hash]    resp
      # @param [Hash]    args
      #
      # @private
      def handle_error is_global, err, msg, session, resp, args, &block
        if is_global
          handler = :global_error_handler
        else
          handler = :err_handler
        end
        unless @app.respond_to? handler
          block_given? and yield err, resp, args
        else
          @app.send handler err, msg, resp, session, args, &block
        end
      end

      # Send response to the client and fire after filter chain if any
      #
      # @param [Boolean] is_global
      # @param [Object]  err
      # @param [Hash]    msg
      # @param [Object]  session
      # @param [Hash]    resp
      # @param [Hash]    args
      #
      # @private
      def response is_global, err, msg, session, resp, args, &block
        if is_global
          block_given? and yield err, resp, args
          # after filter should not interfere response
          after_filter is_global, err, msg, session, resp, args, &block
        else
          after_filter is_global, err, msg, session, resp, args, &block
        end
      end

      # Parse route string
      #
      # @param [String] route
      #
      # @private
      def parse_route route
        return nil unless route
        return nil unless (ts = route.split '.').length == 3
        {
          'route' => route,
          'server_type' => ts[0],
          'handler' => ts[1],
          'method' => ts[2]
        }
      end

      # Forward message
      #
      # @param [Hash]   msg
      # @param [Object] session
      # @param [Hash]   route_record
      #
      # @private
      def do_forward msg, session, route_record, &block
        finished = false
        begin
          @app.sysrpc[route_record['server_type']].msgRemote.forwardMessage(
            session, msg, session.export
          ) { |err, resp, args|
              finished = true
              block_given? and yield err, resp, args
            }
        rescue => err
          block_given? and yield err unless finished
        end
      end

      # Handle message
      #
      # @param [Hash]   msg
      # @param [Object] session
      # @param [Hash]   route_record
      #
      # @private
      def do_handle msg, session, route_record, &block
        handle = Proc.new { |err, resp, args|
          if err
            handle_error(false, err, msg, session, resp, args) { |err, resp, args|
              response false, err, msg, session, resp, args, &block
            }
            return
          end

          @handler_service.handle(route_record, msg, session) { |err, resp, args|
            if err
              handle_error(false, err, msg, session, resp, args) { |err, resp, args|
                response false, err, msg, session, resp, args, &block
              }
              return
            end
            response false, err, msg, session, resp, args, &block
          }
        }
        before_filter false, msg, session, &handle
      end
    end
  end
end
