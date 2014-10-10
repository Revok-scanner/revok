require 'open3'
require 'json'

class Photographer
  
  def initialize(url=nil)
    if url
      @url=url 
    else
      @url=(JSON.parse($datastore['config'], {create_additions:false}))['target']
    end
    
  end

    
  def shot
    result = "FAIL"
    filename = "/tmp/" + `uuidgen`.chomp + '.png'
    log "Generating screenshot of the login page..."

    shot_in, shot_out, shout_err = Open3.popen3("phantomjs --ignore-ssl-errors=true #{File.dirname(__FILE__)}/js/longshot.js #{filename} 20000")
    shot_in.puts "#{@url}"
    shot_in.close
    result = "PASS" if shot_out.read.match(/status: fail/).nil?
    [shot_out, shout_err].each {|pipe| pipe.close}

    if result == "PASS" then
      system("convert #{filename} -resize 640x400 #{filename}")
      base_in, base_out, base_err = Open3.popen3("base64 #{filename}")
      payload = base_out.read.split("\n").join('')
      [base_in, base_out, base_err].each {|pipe| pipe.close}
      log "----screenshot\n#{payload}\n----screenshot\n"
    end
    system("rm -rf #{filename}")
    log "ERROR: #{filename} cannot be removed" if File.exists?("#{filename}")
  end

end
