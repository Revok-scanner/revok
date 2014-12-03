require 'open3'
require 'json'
require 'core/module'

class Photographer < Revok::Module
  
  def initialize
    info_register("Photographer", {"group_name" => "screenshot",
                                "group_priority" => 100,
                                "priority" => 1,
                                "required" => true})
  end

    
  def run
    begin
      @url=(JSON.parse($datastore['config'], {create_additions:false}))['target']
    rescue => exp
       Log.error("#{exp}")
       return
    end
    result = "FAIL"
    filename = "/tmp/" + `uuidgen`.chomp + '.png'
    Log.info("Generating screenshot of the login page...")

    shot_in, shot_out, shout_err = Open3.popen3("phantomjs --ignore-ssl-errors=true --ssl-protocol=any #{File.dirname(__FILE__)}/js/longshot.js #{filename} 25000")
    shot_in.puts "#{@url}"
    shot_in.close
    result = "PASS" if shot_out.read.match(/status: fail/).nil?
    [shot_out, shout_err].each {|pipe| pipe.close}

    if result == "PASS" then
      system("convert #{filename} -resize 640x400 #{filename}")
      base_in, base_out, base_err = Open3.popen3("base64 #{filename}")
      payload = base_out.read.split("\n").join('')
      [base_in, base_out, base_err].each {|pipe| pipe.close}
      Log.info("----screenshot\n#{payload}\n----screenshot\n")
    end
    system("rm -rf #{filename}")
    Log.error("ERROR: #{filename} cannot be removed" if File.exists?("#{filename}"))
  end

end
