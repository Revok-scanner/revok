module Revok

	class Config
		MODULES_DIR = File.expand_path("../modules", File.dirname(__FILE__))
		MSG_QUEUE_USER = ENV["MSG_QUEUE_USER"] != nil ? ENV["MSG_QUEUE_USER"] : "user"
		MSG_QUEUE_PASSWORD = ENV["MSG_QUEUE_PASSWORD"] != nil ? ENV["MSG_QUEUE_PASSWORD"] : "p@ssword"
		MSG_QUEUE_HOST = ENV["MSG_QUEUE_HOST"] != nil ? ENV["MSG_QUEUE_HOST"] : "127.0.0.1"
		MSG_QUEUE_PORT = ENV["MSG_QUEUE_PORT"] != nil ? ENV["MSG_QUEUE_PORT"] : "61612"
		MSG_QUEUE_CERT_PATH = ENV["MSG_QUEUE_CERT_PATH"] != nil ? ENV["MSG_QUEUE_CERT_PATH"] : ""
		WORK_QUEUE = "/queue/work"
		RETURN_QUEUE = "/queue/return"
		USE_SMTP = ENV["USE_SMTP"] != nil ? ENV["USE_SMTP"] : "off"
		SMTP_ADDRESS = ENV["SMTP_ADDRESS"] != nil ? ENV["SMTP_ADDRESS"] : "smtp.example.com"
		SMTP_PORT = ENV["SMTP_PORT"] != nil ? ENV["SMTP_PORT"] : "587"
		SMTP_USER = ENV["SMTP_USER"] != nil ? ENV["SMTP_USER"] : "username"
		SMTP_PASSWORD = ENV["SMTP_PASSWORD"] != nil ? ENV["SMTP_PASSWORD"] : "password"
		EMAIL_ADDRESS = ENV["EMAIL_ADDRESS"] != nil ? ENV["EMAIL_ADDRESS"] : "revok@example.com"
	end

end
