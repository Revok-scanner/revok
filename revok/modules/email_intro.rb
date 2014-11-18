require 'base64'
require 'open3'
require 'json'
require 'resolv'
require 'mail'
require 'core/module'

class Postman1 < Revok::Module
  def initialize
    info_register("Postman1", {"group_name" => "default",
                              "group_priority" => 10,
                              "priority" => 10})
  end

  def run
   begin
     config=$datastore['config']
     @config=JSON.parse(config, {create_additions:false})
     @requestor=@config['email']
     @target=@config['target']
     @whitelist=@config['whitelist']
   rescue => exp
     Log.error("#{exp}")
     return 
   end
    whitelist = Array.new
    @whitelist.each do |item|
      begin
        whitelist.push(item)
      rescue
        Log.warn("Couldn't look up #{item}.")
      end
    end
    @config['whitelist']= whitelist
    $datastore['config'] = JSON.dump(@config)

msg = <<-msg
Greetings,

Your scan of #{@target} has begun. Depending on server load, you should receive a second e-mail with the results in about an hour.

Thanks,

Revok team
msg

    to="#{@requestor}"
    target=@target

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
      subject "Message from Revok: Your scan of #{target} has begun."
      body    msg
    end
    Log.info( "Introduction email is sent" )
   
  end

end
