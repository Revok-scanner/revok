require 'base64'
require 'open3'
require 'json'
require 'resolv'
require 'mail'

class Postman1
  def initialize(config=$datastore['config'])
    @config=JSON.parse(config, {create_additions:false})
    @requestor=@config['email']
    @target=@config['target']
    @whitelist=@config['whitelist']
  end

  def send
    whitelist = Array.new
    @whitelist.each do |item|
      begin
        whitelist.push(item)
      rescue
        log "Couldn't look up #{item}."
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

    log "RESULT: PASS"
  end

end

