$LOAD_PATH << File.dirname(__FILE__)

require 'logger'
require_relative 'core/config'
require_relative 'core/modules'
require_relative 'core/module'
require_relative 'core/framework'
require_relative 'core/module_executor'
require_relative 'core/activemq'
require_relative 'core/multilogger'
require_relative 'core/runserver'

module Revok

	Log = MultiLogger.new
	Log.add_logger(Logger.new(STDOUT))
	case ENV['LOG']
		when "info"
			Log.level = Logger::INFO
		when "warn"
			Log.level = Logger::WARN
		when "debug"
			Log.level = Logger::DEBUG
		when "error"
			Log.level = Logger::ERROR
		when "fatal"
			Log.level = Logger::FATAL
		else
			Log.level = Logger::INFO
	end
	Log.formatter = proc {|severity, datetime, progname, msg|
		"[#{datetime}] #{severity}: #{msg}\n"
	}

	ROOT_PATH = ENV['ROOT_PATH'] != nil ? ENV['ROOT_PATH'] : File.dirname(__FILE__)

end
