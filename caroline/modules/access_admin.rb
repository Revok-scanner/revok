#
# Access Admin Pages Module
# Send HTTP requests with common administrative URIs to check whether these pages can be accessed by the provides user account.
#
require 'json'
require 'rex'
require 'typhoeus'
require 'core/module'
require "#{Revok::Config::MODULES_DIR}/lib/admin_url.rb"

class AdminAccessor < Revok::Module
  include AdminURLs

  def initialize(load_from_file = false, session_file="", flag='s')
    info_register("Access_admin_pages", {"group_name" => "default",
                              "group_priority" => 10,
                              "detail" => "Send HTTP requests with common administrative URIs to check whether these pages can be accessed by the provides user account.",
                              "priority" => 10})
    if(load_from_file)
      @session_data = File.open(session_file).read
    else
      @session_data = nil
    end
  end

  def run
    @session_data = @datastore['session'] if @session_data == nil
    config = @datastore['config']
    def encode64(msg)
      Rex::Text::encode_base64(msg)
    end
    begin
      data = JSON.parse(@session_data, {create_additions:false})
      config = JSON.parse(config, {create_additions:false})
    rescue => exp
      Log.debug(exp.to_s)
      Log.debug(exp.backtrace.join("\n"))
      @session_data = nil
      return
    end
    cookie=data['cookie']
    logtype = config['logtype']
    username = config['username']
    password = config['password']
    target = config['target']
    encoded_auth = encode64(username + ":" + password)
    urls = AURLS
    rpt_uri = Array.new()
    flg = true
    if (target.scan(/\/$/) == [])
      flg = false
    end
    target = target.split("#")[0]
    Log.info( "Sending requests to possible admin URIs..." )
    urls.each do |a_uri|
      
      #generate a GET request for each url in the list
      req = Hash.new()

      #Check if "/" is needed for the uri in the list
      if !flg
        g_uri = target + '/' + a_uri
      else
        g_uri = target + a_uri
      end

      #Generate the request for 2 different authentications
      if logtype == "basic"
        auth = "Basic " + encoded_auth
        req= Typhoeus::Request.new(
          g_uri,
          method: :get,
          headers: { Cookie: cookie, Authorization: auth},
          connecttimeout:5,
          ssl_verifypeer:false
        )
      else
        req= Typhoeus::Request.new(
          g_uri,
          method: :get,
          headers: {Cookie: cookie},
          connecttimeout:5,
          ssl_verifypeer:false
        )
      end

      begin
        resp = req.run
        if resp.code == 200 or (resp.code > 300 and resp.code < 308 and resp.response_headers.scan(/login/) == [])
          if resp.code > 300 and resp.code < 308 and resp.response_body.scan(/<input .*?value="(Login|login|log in|Log in)"/)
            next
          end
           uri = target + a_uri
           rpt_uri.push uri
        end
      rescue
        Log.error("#{$!}")
        break
      end
    end

    if rpt_uri != []
      rpt_uri.each do |ruri|
        list(ruri)
      end
      warn
    else
      abstain
    end
    @session_data = nil
    Log.info("Access admin pages completed")
  end
end
