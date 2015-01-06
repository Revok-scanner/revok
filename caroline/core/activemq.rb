require 'stomp'
require 'time'
require_relative 'config'

module Revok

class ActiveMQClient
	def initialize
		@username = Config::MSG_QUEUE_USER
		@password = Config::MSG_QUEUE_PASSWORD
		@host = Config::MSG_QUEUE_HOST
		@port = Config::MSG_QUEUE_PORT
		@cert_path = Config::MSG_QUEUE_CERT_PATH
	end

	def connect
		if (@connection == nil)
			config = {
				hosts:[{
					login: @username,
					passcode: @password,
					host: @host,
					port: @port.to_i,
					ssl: set_ssl(@cert_path)
				}]
			}
			Log.debug("Connecting ActiveMQ: #{config}")
			begin
				@connection = Stomp::Connection.new(config)
				@connection.subscribe(Config::WORK_QUEUE, {ack:'client'})
			rescue => exp
				Log.error(exp.to_s)
				Log.debug(exp.backtrace.join("\n"))
				@connection = nil
			end
		end
		Log.debug("ActiveMQ connection: #{@connection}")
		return @connection
	end

	def publish(msg)
		return false if (@connection == nil)
		Log.debug("Pushing message \"#{msg.to_s}\" to queue #{Config::RETURN_QUEUE}")
		@connection.publish(Config::RETURN_QUEUE, msg, {persistent:false,expires:(Time.now.to_i*1000)+(259200*1000),'amq-msg-type'=>'text'})
	end

	def disconnect
		if @connection
			@connection.disconnect if !@connection.closed?
		end
	end

	attr_accessor	:username, :password, :host, :port, :cert_path
	attr_reader		:connection

	private
		def set_ssl(cert_path = "")
			ssl = false
			if File.exist?(cert_path)
				ssl = Stomp::SSLParams.new(ts_files:cert_path)
			end
			return ssl
		end
end

end
