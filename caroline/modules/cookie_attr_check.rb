#
# Cookie Attributes Checking Module
# Search for cookies without Secure flag or HttpOnly flag, and session cookies without expires attribute.
#
require 'time'
require 'json'
require 'net/http'
require 'base64'
require 'core/module'

class CookieAttrChecker < Revok::Module

  def initialize(load_from_file = false, session_file = "")
    info_register("Cookie_Attribute_Checker", {"group_name" => "default",
                              "group_priority" => 10,
                              "detail" => "Search for cookies without Secure flag or HttpOnly flag, and session cookies without expires attribute.",
                              "priority" => 10})
    if(load_from_file)
      begin
        @session_data = File.open(session_file, 'r').read
      rescue => exp
        @session_data = ""
        Log.warn(exp.to_s)
        Log.debug(exp.backtrace.join("\n"))
      end
    end
  end

  def run
    @session_data = @datastore['session'] if @session_data == nil
    @session_id = @datastore['session_id'] if @session_id == nil
    @config = @datastore['config']
    begin
      @session = JSON.parse(@session_data, {create_additions:false})
      @config = JSON.parse(@config, {create_additions:false})
    rescue => exp
      Log.warn(exp.to_s)
      Log.debug(exp.backtrace.join("\n"))
      @session_data = nil
      @session_id = nil
      return
    end
    cookie_attr_check
    Log.info("Cookie attribute check completed")
  end
  
  def cookie_attr_check
    set_cookies = Hash.new
    not_secure = Hash.new
    not_httponly = Hash.new
    expired = Hash.new

    begin
      domain = URI(@config['target']).host
      session_id = @session_id
      id=0
      @session['responses'].each_pair do |k, v|
        request = @session['requests'][k].split("\r\n")[0].gsub(/HTTP\/1.*/,"")
        if request.include? domain and v.scan(/\r\nSet-Cookie:(.*?)\r\n/i)!=[]
          set_cookie = v.scan(/\r\nSet-Cookie:(.*?)\r\n/i)[0][0].strip
          set_cookies["#{request}"] = set_cookie
        end
      end 

      set_cookies.each_pair do |k, v|
        if v.scan(/secure/i) == []
          not_secure["#{k}"] = v
        end
        if v.scan(/httponly/i) == []
          not_httponly["#{k}"] = v
        end
        if session_id != nil and v.include? session_id and v.scan(/expires/i) == []
            expired["#{k}"] = v
        end
      end
    rescue => exp
      error
      Log.warn(exp.to_s)
      Log.debug(exp.backtrace.join("\n"))
    end

    if not not_secure.empty?
      nsecure = String.new
      if not_secure.size == set_cookies.size
        nsecure = "All of the cookies.<br/>"
      else
        not_secure.each {|k,v| nsecure += "#{v} (response of #{k})<br/>"}
        Log.warn("'secure' not set on cookies:#{not_secure}")
      end
      advise({"description" => "Cookies without Secure flag is allowed to be transmitted through an unencrypted channel which makes it susceptible to sniffing.", "cookies" => nsecure, "advice" => "Use the Secure flag when generating a cookie.", "reference" => "CWE-614 - http://cwe.mitre.org/data/definitions/614.html", "name" => "Cookie Attributes - Secure flag"})
    end
    if not not_httponly.empty?
      nhttponly = String.new
      if not_httponly.size == set_cookies.size
        nhttponly = "All of the cookies.<br/>"
      else
        not_httponly.each {|k,v| nhttponly += "#{v} (response of #{k})<br/>"}
        Log.warn("'httponly' not set on cookies:#{not_httponly}")
      end
      advise({"description" => "Cookies without HttpOnly flag is susceptible to be accessed by client-side code.", "cookies" => nhttponly, "advice" => "Use the HttpOnly flag when generating a cookie.", "reference" => "OWASP - https://www.owasp.org/index.php/HttpOnly", "name" => "Cookie Attributes - HttpOnly flag"})
    end
    if not expired.empty?
      exp = String.new
      if expired.size == set_cookies.size
        exp = "All of the cookies.<br/>"
      else
        expired.each {|k,v| exp += "#{v} (response of #{k})<br/>"}
        Log.warn("'expires' not set on cookies:#{expired}")
      end
      advise({"description" => "Session cookies without expires attribute will stay active until user manually ends the browser process. It is a failure in secure session management when an application does not have a defined session expiration time-out set.", "cookies" => exp, "advice" => "Set expiration time for session cookies.", "reference" => "OWASP - https://www.owasp.org/index.php/Testing_for_cookies_attributes_(OWASP-SM-002)", "name" => "Cookie Attributes - Session expiration"})
    end
    if not_secure.empty? and not_httponly.empty? and expired.empty?
      abstain
    end
    @session_data = nil
    @session_id = nil
  end
   
  def str_to_hex(s)
    s = s.gsub(/[^a-f0-9]/, "")
    data = s.scan(/../).map { |x| x.hex.chr }.join
    return check_decoded_str(s, data, "hex")
  end

  def str_to_base64(s)
    data = Base64.decode64(s)
    return check_decoded_str(s, data, "base64")
  end

  def check_decoded_str(plain_cookie, decode_cookie, type)
    flag = 0
    pattern = {
      'ip' => '\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}',
      'email' => '[a-zA-Z0-9]+[_?a-zA-Z0-9]+\@[a-zA-Z]+[-?a-zA-Z]*\.+[a-zA-Z]+'
    }
    if @username != "" then pattern['username'] = @username end
    
    pattern.each_pair do |k, v|
      if decode_cookie.scan(/#{v}/).size > 0
        if k == "ip" and /^((\d{1,2}|1\d\d|2[0-4]\d|25[0-5])\.){3}(\d{1,2}|1\d\d|2[0-4]\d|25[0-5])$/.match(decode_cookie.scan(/#{v}/)[0]) == nil
          break
        end 
        flag += 1
        msg = "#{k} information is found in #{type} encoded cookie: #{plain_cookie}<br>"
        @report += "#{msg}"
        Log.info(msg)
      end
    end
    return flag
  end
end
