require 'base64'
require 'open3'
require 'json'
require 'mail'
require 'core/module'
class Postman2 < Revok::Module

  def initialize
    info_register("Postman2", {"group_name" => "default",
                              "group_priority" => 10,
                              "priority" => 10})
  end

  def run
    begin
      config=$datastore['config']
      advice_report=$datastore['advice_report']
      advice_email_body=$datastore['advice_email_body']
      @config=config
      @advice_report=advice_report
      @advice_email_body=advice_email_body
    rescue => exp
       Log.error("#{exp}")
       return
    end
    config = JSON.parse(@config, {create_additions:false})
    target = config['target']
    report = @advice_report

    subject = ""
    msg = ""
    email_body=""
    system("zip -qj #{File.dirname(__FILE__)}/report/report.html.zip #{File.dirname(__FILE__)}/report/report_#{$datastore['timestamp']}.html")
    if (report.nil?) or  not File.exists?("#{File.dirname(__FILE__)}/report/report.html.zip")
      subject = "There was a problem with your scan of #{target}."
      msg = <<-problem_msg
Unfortunately, Revok seems to have encountered an issue trying to scan #{target}. You're welcome to try again. The full log for your scan here: http://#{ENV["HOSTNAME"]}/log?uid=#{$datastore['RUN_ID']}
problem_msg
    else
      subject = "The results of your scan of #{target} are ready."
      msg = @advice_email_body
    end

msg_body = <<-body
Greetings,

#{msg}

Thanks

Revok team
body

    to="#{config['email']}"
    Mail.defaults do
      delivery_method:smtp,{:address    => ENV["SMTP_ADDRESS"],
                            :port       => ENV["SMTP_PORT"].to_i,
                            :user_name  => ENV["SMTP_USER"],
                            :password   => ENV["SMTP_PASSWORD"],
                            :enable_starttls_auto => true }
    end

    Mail.deliver do
      from    ENV["EMAIL_ADDRESS"]
      to      to
      subject "Message from Revok: #{subject}"
      body    msg_body
      add_file "#{File.dirname(__FILE__)}/report/report.html.zip"
    end
    system("rm -f #{File.dirname(__FILE__)}/report/report.html.zip")
    system("if test -f  #{File.dirname(__FILE__)}/report/report.html.zip ;then echo -e \" [*] Delete zip file faild.\"; else echo -e \" [*] Delete zip file successfully.\"; fi")
    log "Report email is sent\n"
   
  end
end
