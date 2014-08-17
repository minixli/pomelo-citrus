# Author:: MinixLi (gmail: MinixLi1986)
# Homepage:: http://citrus.inspawn.com
# Date:: 24 July 2014

module Citrus
  # Utils
  #
  #
  module Utils
    # PathUtil
    #
    #
    module PathUtil
      # Get system remote service path
      #
      # @param [String] role
      def get_sys_remote_path role
        path = File.join File.dirname(__FILE__), '/../common/remote/', role
        File.exists?(path) ? path : nil
      end

      # Get user remote service path
      #
      # @param [String] app_base
      # @param [String] server_type
      def get_user_remote_path app_base, server_type
        path = File.join app_base, '/app/servers/', server_type, 'remote'
        File.exists?(path) ? path : nil
      end

      # Compose remote path record
      #
      # @param [String] namespace
      # @param [String] server_type
      # @param [String] path
      def remote_path_record namespace, server_type, path
        { :namespace => namespace, :server_type => server_type, :path => path }
      end

      # Get handler path
      #
      # @param [String] app_base
      # @param [String] server_type
      def get_handler_path app_base, server_type
        path = File.join app_base, '/app/servers/', server_type, 'handlers'
        File.exists?(path) ? path : nil
      end
    end
  end
end
