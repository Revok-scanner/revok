require 'open3'
require 'json'
require 'core/module'
require 'core/activemq'

class Photographer < Revok::Module
  
  def initialize
    info_register("Photographer", {"group_name" => "screenshot",
                                "group_priority" => 100,
                                "priority" => 1,
                                "required" => true})
  end

  def send_msg(img, client)
    msg = Hash.new
    msg['type'] = "screenshot"
    msg['uid'] = @datastore['run_id']
    msg['img'] = img
    Log.info("Publishing modules list")
    client.publish(JSON.generate(msg).to_s)
  end
    
  def run
    begin
      url = (JSON.parse(@datastore['config'], {create_additions:false}))['target']
      queue_client = Revok::ActiveMQClient.new
      Log.info("Connecting to messages queue...")
      queue_client.connect
    rescue => exp
      Log.error(exp.to_s)
      Log.debug(exp.backtrace.join("\n"))
      return
    end
    result = "FAIL"
    filename = "/tmp/" + `uuidgen`.chomp + '.png'
    Log.info("Generating screenshot of the login page...")

    shot_in, shot_out, shout_err = Open3.popen3("phantomjs --ignore-ssl-errors=true --ssl-protocol=any #{Revok::Config::MODULES_DIR}/js/longshot.js #{filename} 25000")
    shot_in.puts "#{url}"
    shot_in.close
    result = "PASS" if shot_out.read.match(/status: fail/).nil?
    [shot_out, shout_err].each {|pipe| pipe.close}

    if result == "PASS" then
      system("convert #{filename} -resize 640x400 #{filename}")
      base_in, base_out, base_err = Open3.popen3("base64 #{filename}")
      payload = base_out.read.split("\n").join('')
      [base_in, base_out, base_err].each {|pipe| pipe.close}
      img = "----screenshot\n#{payload}\n----screenshot\n"
      Log.info(img)
      begin
        send_msg(img, queue_client)
      rescue => exp
        Log.error(exp.to_s)
        Log.debug(exp.backtrace.join("\n"))
      ensure
        queue_client.disconnect
      end
    end
    system("rm -rf #{filename}")
    Log.warn("Warning: #{filename} cannot be removed") if File.exists?("#{filename}")
  end

end
