#
# Login Brute Force Module
# Check whether prevention for login brute force exists by logging in after several times' failed authentication.
#
require 'rex/socket'
require 'rex/proto/http'
require 'rex/text'
require 'digest'
require 'rex/proto/ntlm/crypt'
require 'rex/proto/ntlm/constants'
require 'rex/proto/ntlm/utils'
require 'rex/proto/ntlm/exceptions'
require 'json'
require 'core/module'

class BruteForceChecker < Revok::Module

  def initialize(load_from_file = false, session_file = "")
    info_register("Login_Brute_Force", {"group_name" => "default",
                              "group_priority" => 10,
                              "detail" => "Check whether prevention for login brute force exists by logging in after several times' failed authentication.",
                              "priority" => 10})
    if (load_from_file)
      begin
        @session_data = File.open(session_file, 'r').read
      rescue => exp
        @session_data = ""
        Log.warn(exp.to_s)
        Log.debug(exp.backtrace.join("\n"))
      end
    end
  end

  def _get_method_from_req(req)
    if req[0,3] == 'GET'
      return 'GET'
    elsif req[0,3] == 'PUT'
      return 'PUT'
    elsif req[0,4] == 'POST'
      return 'POST'
    elsif req[0,4] == 'HEAD'
      return 'HEAD'
    elsif req[0,5] == 'TRACE'
      return 'TRACE'
    elsif req[0,7] == 'OPTIONS'
      return 'OPTIONS'
    end
    return nil
  end

  # _find_new_target: find a final url when being redirected for basic auth
  def _find_new_target resp
    resp.downcase.scan(/location:\s(.*)\r/)
    redir_url = $1
    @requests.each_pair do |k,v|
      if v.scan(/^GET #{redir_url} HTTP/)!=[]
        if @responses[k].start_with? "HTTP/1.1 30"
          k = _find_new_target @responses[k]
        end

        #p "k = "+ k
        return k
      end
    end
    return nil
  end

  def _get_login_req
    @requests = @session_data['requests']
    @responses = @session_data['responses']
    @logtype = @config['logtype']
    @username = @config['username']
    @password = @config['password']
    login = @config['login']
    target = @config['target']
    
    #Scan for login request
    if @logtype == "basic"
      target << '/' if target[-1] != '/'
      #p "target url: " + target
      @requests.each_pair do |k,v|
        if v.scan(/^GET #{target} HTTP/)!=[]
          if @responses[k].start_with? "HTTP/1.1 30"
            k = _find_new_target @responses[k]
          end
          return @requests[k]
        end
      end
    elsif @logtype == "normal"
      @requests.each_pair do |k,v|
        if v.scan(/^POST #{login}/)!=[] and v.scan(/#{@username}/)!=[] and v.scan(/#{@password}/)!=[]
          return @requests[k]
        end
      end
    end
    return nil
  end

  def _get_new_test_req_basic
    # get random pw of the same length
    begin
      rand_pw = (1..@password.length).map { (65 + rand(26)).chr }.join
    end while rand_pw == @password

    old_cred = "#{@username}:#{@password}"
    old_cred_base64 = Base64.encode64(old_cred).strip

    new_cred = "#{@username}:#{rand_pw}"
    new_cred_base64 = Base64.encode64(new_cred).strip

    new_req = @login_req.gsub("Basic #{old_cred_base64}", "Basic #{new_cred_base64}")
    return new_req
  end

  def _get_new_test_req
    # get random pw of the same length
    begin
      rand_pw = (1..@password.length).map { (65 + rand(26)).chr }.join
    end while rand_pw == @password
    new_req = @login_req.gsub("=#{@password}", "=#{rand_pw}")
    return new_req
  end

  def _are_same_resp(resp1, resp2)
    # check a few to judge if two login responses are the same
    if resp1.code != resp2.code
      return false
    end

    if resp1.code == 200
      if resp1.body != resp2.body
        return false
      end
    else
      if resp1.headers['location'] != resp2.headers['location']
        return false
      end
    end

    return true
  end

  def run
    abstain
    @session_data = @datastore['session'] if @session_data == nil
    max_run = 10
    time_out = 30
    cnt = 0
    begin
      @config = @datastore['config']
      @session_data = JSON.parse(@session_data, {create_additions:false})
      @config = JSON.parse(@config, {create_additions:false})
      Log.info("Start bruteforcing...")
      @login_req = _get_login_req
      if not @login_req
        Log.info("No login request found")
        @session_data = nil
        return
      end

      uri = URI(@config['target'])
      host = uri.host
      port = uri.port
      context = {}
      ssl = (uri.scheme == 'https' ? true : false)
      ssl_version = nil
      proxies = nil
      conn = Rex::Proto::Http::Client.new(host, port, context, ssl, ssl_version, proxies)

      # send one to get successful login response in response object
      if @logtype == 'basic'
        success_resp = conn.send_recv(@login_req, time_out)
      end
      if @logtype == 'normal'
        success_resp = conn.send_recv(@login_req, time_out)
      end

      for i in 1..max_run
        # scan location of password in login_req
        # mangle password
        # send
        if @logtype == 'basic'
          new_test_req =  _get_new_test_req_basic
        end

        if @logtype == 'normal'
          new_test_req =  _get_new_test_req
        end

        #resp = conn.send_recv(new_test_req, time_out)
        #NOTE: if basic login fails with 401 error when calling send_recv(), req attribute should have req.opts and a string-type req can not be used. That's because send_recv() will automatically try send_auth() when auth fails. see send_auth() in lib/rex/proto/http/client.rb:217 (librex)
        conn.send_request(new_test_req, time_out)
        resp = conn.read_response(time_out)
        resp.request = new_test_req.to_s if resp
          
        # check response
        # - get successful response from session data
        # - compare new response with it
        if _are_same_resp(resp, success_resp)
          # this means the login with invalid password has been successful. AUTH issue
          Log.warn "Authentication failed" 
          break
        end
 
        if i == 1
          first_invalid_resp = resp 
        else
          # if new response becomes different with the first invalid response
          if not _are_same_resp(resp, first_invalid_resp)
            Log.info("Bruteforcing mitigation is being applied")
            break
          end
        end
      end

      if i == max_run
        advise({'method'=>_get_method_from_req(@login_req), 'login'=>@config['target']})
        Log.info("Bruteforcing is working")
      end
    rescue => exp
      error
      Log.error(exp.to_s)
      Log.debug(exp.backtrace.join("\n"))
    end
    @session_data = nil
  end #run
end
