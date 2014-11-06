#
# Access Admin Pages Module
# Send HTTP requests with common administrative URIs to check whether these pages can be accessed by the provides user account.
# 

$: << "#{File.dirname(__FILE__)}/lib/"

require 'report.ut'
require 'json'
require 'admin_url'
require 'rex'
require 'typhoeus'

class AdminAccessor
  include AdminURLs
  include ReportUtils

  def initialize(config=$datastore['config'],session_data=$datastore['session'],flag='s')
    @config=config
    if flag=='f'
      @session_data=File.open(session_data).read
    else
      @session_data=session_data
    end
  end
  
  def run

    def encode64(msg)
      Rex::Text::encode_base64(msg)
    end

    data = JSON.parse(@session_data, {create_additions:false})
    config = JSON.parse(@config, {create_additions:false})
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

    log "Sending requests to possible admin URIs..." 

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
        log "ERROR: #{$!}" 
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
    log "access_admin is done"

  end

end
