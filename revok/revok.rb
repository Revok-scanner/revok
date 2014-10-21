$LOAD_PATH << File.dirname(__FILE__)

require_relative 'core/framework'

module Revok
	DATASTORE = Hash.new
	MODULES = Hash.new
end
