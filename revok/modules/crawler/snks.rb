require 'json'

class Snks
  
  def initialize(session_string,flag)
    if flag=='f'
      begin
        @session_data=File.open(session_string,'r').read 
      rescue
        @session_data=""
        return nil
      end
    elsif flag=="s"
      @session_data=session_string
    else
      log 'unknow flag' 
      return nil
    end
  end

  def run
    $session_data = nil

    def req_to_url(line)
      line.gsub(/HTTP\/1\.1.*/,'').rstrip.gsub(/^GET /,'').gsub(/^POST /,'')
    end

    def normalize_url(url, markers)
      markers.each_with_index do |tck,idx|
        #url = url.gsub($session_data['tags'][tck],"p#{idx+1}")
        url = url.gsub($session_data['tags'][tck],"param")
      end
      url
    end

    $session_data = JSON.parse(@session_data, {create_additions:false})

    markers = Array.new
    rsps = Array.new
    $session_data['tags'].each do |tck,prm|
      $session_data['responses'].each do |tckp,rsp|
        code=rsp.scan(/HTTP\/1.1 (.*?)\r\n/)[0][0].to_i
        next if ((code>= 300 && code<=303) || code==307)
        if rsp.include? prm then 
          markers << tck.to_i 
          rsps << tckp.to_i
        end
      end
    end

    markers = markers.uniq.sort
    markers.map! {|x| x.to_s}
    rsps = rsps.uniq.sort
    rsps.map! {|x| x.to_s}

    snks = Hash.new
    ids = Hash.new
    rsps.each do |tck|
      id = normalize_url(req_to_url($session_data['requests'][tck].lines.first),markers)
      next if not ids[id].nil?
      ids[id] = tck

      params = Array.new
      markers.each do |mrk_tck|
        params << mrk_tck if $session_data['responses'][tck].include? $session_data['tags'][mrk_tck]
      end
      params = params.uniq.sort
      params.map! {|x| x.to_s}

      srcs = Array.new
      params.each do |prm_tck|
        req = $session_data['requests'][tck]
        body = req.gsub(req.split("\r\n\r\n")[0], "")
        if req.lines.first.include? $session_data['tags'][prm_tck] or body.include? $session_data['tags'][prm_tck]
          srcs << tck
          next
        end
        $session_data['requests'].each do |req_tck,req|
          body = req.gsub(req.split("\r\n\r\n")[0], "")
          srcs << req_tck if req.lines.first.include? $session_data['tags'][prm_tck] or body.include? $session_data['tags'][prm_tck]
        end
      end
      srcs = srcs.uniq.sort
      srcs.map! {|x| x.to_s}

      snks[tck] = {
        "id"=>id,
        "params"=>params,
        "srcs"=>srcs,
      }

    end
    log "RESULT: PASS" 
    return JSON.dump({'snks'=>snks}).to_s
  end
end

