# Author:: MinixLi (gmail: MinixLi1986)
# Homepage:: http://citrus.inspawn.com
# Date:: 25 July 2014

module Citrus
  # Common
  #
  #
  module Common
    # Service
    #
    #
    module Service
      # ConnectionService
      #
      #
      class ConnectionService
        # Initialize the service
        #
        # @param [Object] app
        def initialize app
          @server_id = app.server_id
          @conn_count = 0
          @logined_count = 0
          @logined = {}
        end

        # Add logined user
        #
        # @param [String] uid
        # @param [Hash]   info
        def add_logined_user uid, info={}
          @logined_count += 1 unless @logined[uid]
          info[:uid] = uid
          @logined[uid] = info
        end

        # Increase connection count
        def increase_conn_count
          @conn_count += 1
        end

        # Remove logined user
        #
        # @param [String] uid
        def remove_logined_user uid
          @logined_count -= 1 if @logined[uid]
          @logined.delete uid
        end

        # Decrease connection count
        #
        # @param [String] uid
        def decrease_conn_count uid
          @conn_count -= 1 if @conn_count > 0
          remove_logined_user uid unless uid.empty?
        end

        # Get statistics info
        def get_statistics_info
          {
            :server_id => @server_id,
            :conn_count => @conn_count,
            :logined_count => @logined_count,
            :logined_list => @logined.values
          }
        end
      end
    end
  end
end
