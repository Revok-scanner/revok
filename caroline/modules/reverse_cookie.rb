#
# Reverse Cookie Module
# Check whether critical user information are kept in simply encoded cookies.
#
require 'time'
require 'json'
require 'net/http'
require 'base64'
require 'core/module'

class CookieReverser < Revok::Module

  def initialize(load_from_file = false, session_file = "")
    info_register("Reverse_Cookie", {"group_name" => "default",
                              "group_priority" => 10,
                              "priority" => 10,
                              "detail" => "Check whether critical user information are kept in simply encoded cookies."})
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
      error
      @session_data = nil
      @session_id = nil
      return
    end
    reverse_cookie_test
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
        msg = "#{k} information is found in #{type} encoded cookie: #{plain_cookie}<br/>"
        @report += "#{msg}"
        Log.warn(msg)
      end
    end
    return flag
  end

  def reverse_cookie_test
    result = true
    cookies = Array.new()
    begin
      @username = @config['username']
      cookies = @session['cookie'].scan(/Cookie:(.*?)$/)[0][0].split(";")
      @report = String.new()

      Log.info("Scan for critical information in plain, base64 and hex decoded cookies...")
      cookies.each do |k|
        cookie = k.gsub(/^.*?=/, "")
        if check_decoded_str(cookie, cookie, "plain") + str_to_base64(cookie) + str_to_hex(cookie) > 0
          result = false
        end
      end
    rescue => exp
      error
      Log.warn(exp.to_s)
      Log.debug(exp.backtrace.join("\n"))
    end

    if result == true
      abstain
      Log.info("No critical info was found")
    else
      advise({"cookies" => @report})
    end
  end
end

  
