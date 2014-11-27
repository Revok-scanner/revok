module Revok
module Rest
	class Config
		REALM_MESSAGE = "caroline REST API authorization needed"
		USER = ENV["REST_USER"] != nil ? ENV["REST_USER"] : "user"
		PASSWORD = ENV["REST_PASSWORD"] != nil ? ENV["REST_PASSWORD"] : "p@ssword"
		PORT = ENV["REST_PORT"].to_i != nil ? ENV["REST_PORT"].to_i : 8443
		ACCESS_LOG_FORMAT = "[%{%Y-%m-%d %H:%M:%S %z}t] ACCESS: %a %u \"%r\" %s %b"
		MSG_QUEUE_USER = ENV["MSG_QUEUE_USER"] != nil ? ENV["MSG_QUEUE_USER"] : "user"
		MSG_QUEUE_PASSWORD = ENV["MSG_QUEUE_PASSWORD"] != nil ? ENV["MSG_QUEUE_PASSWORD"] : "p@ssword"
		MSG_QUEUE_HOST = ENV["MSG_QUEUE_HOST"] != nil ? ENV["MSG_QUEUE_HOST"] : "127.0.0.1"
		MSG_QUEUE_PORT = ENV["MSG_QUEUE_PORT"] != nil ? ENV["MSG_QUEUE_PORT"] : "61612"
		MSG_QUEUE_CERT_PATH = ENV["MSG_QUEUE_CERT_PATH"] != nil ? ENV["MSG_QUEUE_CERT_PATH"] : ""
		WORK_QUEUE = "/queue/work"
		RETURN_QUEUE = "/queue/return"

	end

end
end
