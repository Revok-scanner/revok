require_relative 'rest'
require_relative 'config'
require_relative 'mono_logger'
require_relative 'activemq'

module Revok
module Rest

	Log = MonoLogger.new(STDOUT)
	case ENV['LOG']
		when "info"
			Log.level = MonoLogger::INFO
		when "warn"
			Log.level = MonoLogger::WARN
		when "debug"
			Log.level = MonoLogger::DEBUG
		when "error"
			Log.level = MonoLogger::ERROR
		when "fatal"
			Log.level = MonoLogger::FATAL
		else
			Log.level = MonoLogger::INFO
	end
	Log.formatter = proc {|severity, datetime, progname, msg|
		"[#{datetime}] #{severity}: #{msg}\n"
	}

	ROOT_PATH = ENV['ROOT_PATH'] != nil ? ENV['ROOT_PATH'] : File.dirname(__FILE__)

end
end
