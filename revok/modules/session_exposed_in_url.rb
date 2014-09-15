#
# Session Exposed in Url Module
# Check whether session id is exposed in requested URLs.
#

$: << "#{File.dirname(__FILE__)}/lib/"
require 'report.ut'
require 'json'
require 'typhoeus'
require 'net/http'
require 'rex'
require 'session_check.rb.ut'

include Sess
class SessionExposureCheckor 
  include ReportUtils
  def initialize(config=$datastore['config'],session_data=$datastore['session'],flag='s')
    @config=config
    if flag=='f'
      begin
        @session_data=File.open(session_data,'r').read 
      rescue =>exp
        log exp.to_s 
        @session_data=""
      end
    elsif flag=="s"
      @session_data=session_data
    else
      log 'unknow flag' 
      return nil
    end
  end
  
  def session_id_detect
    session_id = String.new()
    cookies = Array.new()
    requests = Hash.new()
    login_redir = Array.new()
    login_request = 0

    session = JSON.parse(@session_data, {create_additions:false})
    config = JSON.parse(@config, {create_additions:false})
    cookies = session['cookie'].scan(/Cookie:(.*?)$/)[0][0].split(";")
    requests = session['requests']
    logtype = config['logtype']
    username = config['username']
    password = config['password']
    login = config['login']
    login_page = login.split("/")[login.split("/").size-1]

    if logtype == "normal"
      #Scan for login request    
      requests.each_pair do |k,v|
        body = v.gsub(v.split("\r\n\r\n")[0], "")
        if v.scan(/^POST/)!=[] and body!= "" and body.scan(/#{username}/)!=[] and body.scan(/#{password}/)!=[]
          login_request = k.to_i
          @login_request = login_request
          $datastore['login_request'] = @login_request
          break
        end
      end
 
      #Scan for the first request after login 
      if login_request > 0 and requests["#{login_request+1}"] != nil
        req  = requests["#{login_request+1}"]
      else
        log "Login request or request after login isn't scanned." 
        return
      end
    end

    #Detect session ID from cookies
    cookies.each do |k|
      k=k.split("=")[0]
      if logtype == "normal"
        test_req = req.gsub(/#{k}=.*?;|#{k}=.*?$/, "")
        url=req.match(/\s(http.*?)\sHTTP\//)[1]
        uri=URI(url)
        host=uri.host
        port = uri.port
        context = {}
        ssl = (uri.scheme=='https'?true:false)
        ssl_version = nil
        proxies = nil
        conn=Rex::Proto::Http::Client.new(host,port, context, ssl, ssl_version, proxies)

        begin
          resp = conn.send_recv(test_req, 125)
        rescue
          log "ERROR: #{$!}" 
        end

        if resp.headers['Location'] != nil
          location = resp.headers['Location']
          login_redir = location.scan(/#{login}|#{login_page}/)
        end

        if (resp.code > 300 and login_redir != []) or resp.code == 403 #drupal returns 403
          session_id = k.gsub(/=.*?$/, "").strip
          break
        end
      
      elsif logtype == "basic"
        session_id = k.gsub(/=.*?$/, "").strip if k.scan(/sess/i) != []
        break
      end
    end

    if session_id != ""
      @session_id=session_id
      $datastore['session_id'] = session_id
      log "The key of session ID is detected: #{session_id}" 
    else
      log "Session ID isn't detected" 
    end

  end
  
  def exposure_check
    session_val = String.new
    url = String.new
    vul = Array.new
    begin
      if @session_id != nil
        session = JSON.parse(@session_data, {create_additions:false})
        cookies = session['cookie'].gsub(/Cookie:/, "").split(";")
        cookies.each do |k|
          if k.include? "#{@session_id}="
            session_val = k.gsub(/#{@session_id}=/, "").strip 
            break
          end
        end

        session['requests'].each_pair do |k, v|
          request = v.split("\r\n")[0].gsub(/HTTP\/1.*/, "")
          if request.include? session_val
            vul.push(request)
          end
        end
      end
    rescue => excep
      error
      log excep.to_s 
    end

    if vul.size == 0
      abstain
      log "No session ID found in urls"  
    else
      vul=vul.uniq
      vul.each do |k|
        log "Session exposed in url of request: #{k}" 
        k = k.gsub(/POST/, "POST request for").gsub(/GET/, "GET request for")
        list("#{k}")  
      end
      warn({"name" => "session_exposed_in_url"})
    end

  end
  
end
