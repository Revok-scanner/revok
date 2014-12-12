require 'resolv'
require 'mail'
require 'fileutils'

module Revok
	class Postman

		def self.send_intro(email, target)
			msg = <<-msg
Greetings,

Your scan of #{target} has begun. Depending on server load, you should receive a second e-mail with the results in about an hour.

Thanks,

Revok team
msg

			Mail.defaults do
				delivery_method:smtp,{:address    => Config::SMTP_ADDRESS,
							:port       => Config::SMTP_PORT.to_i,
							:user_name  => Config::SMTP_USER,
							:password   => Config::SMTP_PASSWORD,
							:enable_starttls_auto => true }
			end

			Mail.deliver do
				from    Config::EMAIL_ADDRESS
 				to      email
				subject "Message from Revok: Your scan of #{target} has begun."
				body    msg
			end
			Log.info "Introduction email sent"
		end

		def self.send_report(email, target, advice_email_body, timestamp, failed = ture)
			subject = ""
			msg = ""
			email_body=""
			system("zip -qj #{Revok::ROOT_PATH}/report/report.zip #{Revok::ROOT_PATH}/report/#{timestamp}_report.html #{Revok::ROOT_PATH}/report/#{timestamp}_log.txt")
			if (failed) or not File.exists?("#{Revok::ROOT_PATH}/report/report.zip")
				subject = "There was a problem with your scan of #{target}."
				msg = <<-problem_msg
Unfortunately, Revok seems to have encountered an issue trying to scan #{target}. You're welcome to try again. The full log for your scan is attached.
problem_msg
			else
				subject = "The results of your scan of #{target} are ready."
				msg = advice_email_body
			end

			msg_body = <<-body
Greetings,

#{msg}

Thanks

Revok team
body

			Mail.defaults do
				delivery_method:smtp,{:address    => Config::SMTP_ADDRESS,
							:port       => Config::SMTP_PORT.to_i,
							:user_name  => Config::SMTP_USER,
							:password   => Config::SMTP_PASSWORD,
							:enable_starttls_auto => true }
			end

			Mail.deliver do
				from    Config::EMAIL_ADDRESS
				to      email
				subject "Message from Revok: #{subject}"
				body    msg_body
				add_file "#{Revok::ROOT_PATH}/report/report.zip"
			end
			begin
				FileUtils.rm("#{Revok::ROOT_PATH}/report/report.zip")
			rescue => exp
				Log.warn("Remove file error: #{exp.to_s}")
				Log.debug(exp.backtrace.join("\n"))
			end
			Log.info "Report email is sent"
		end
	end
end
