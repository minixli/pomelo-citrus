# Author:: MinixLi (gmail: MinixLi1986)
# Homepage:: http://citrus.inspawn.com
# Date:: 16 July 2014

require 'citrus/application'
require 'citrus/util/events'

module Citrus
  # Create a citrus application
  #
  # @param [Hash] args
  def self.create_app args={}
    app = Application.new args

    Object.class_eval {
      def app
        return app
      end
    }
    return app
  end

  # Load all the components
  Dir.glob(File.expand_path('../../citrus/components/*.rb', __FILE__)).each { |filepath|
    require filepath
  }
end
