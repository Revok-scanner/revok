require 'logger'

module Revok

	class MultiLogger
		def initialize(args = {})
			@level = args[:level] || Logger::Severity::INFO
			@loggers = []

			Array(args[:loggers]).each { |logger| add_logger(logger) }
		end

		def add_logger(logger)
			logger.level = @level
			logger.formatter = @formatter if (@formatter)
			@loggers << logger
		end

		def level=(level)
			@level = level
			@loggers.each { |logger| logger.level = @level }
		end

		def formatter=(formatter)
			@formatter = formatter
			@loggers.each { |logger| logger.formatter = @formatter }
		end

		def close
			@loggers.map(&:close)
		end

		def close_user_logger
			for i in 1...@loggers.length
				@loggers[i].close
				@loggers.delete_at(i)
			end
		end

		Logger::Severity.constants.each do |level|
			define_method(level.downcase) do |*args|                
				@loggers.each { |logger| logger.send(level.downcase, *args) }
			end
 
			define_method("#{ level.downcase }?".to_sym) do
				@level <= Logger::Severity.const_get(level)
			end
  		end

		attr_reader		:level, :formatter
	end
end
