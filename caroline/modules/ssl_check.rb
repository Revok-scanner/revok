#
# SSL Mis-configuration Checking Module
# Check SSL/TLS mis-configuration which makes the communication between browser and server not secure, such as weak cipher, invalid certificate etc.
#

require 'timeout'
require 'net/http'
require 'typhoeus'
require 'core/module'
require "#{Revok::Config::MODULES_DIR}/lib/ssl_check.rb.ut"

class SSLChecker < Revok::Module
  include SSLCheck

  def initialize
    info_register("SSL_Mis-configuration_Checker", {"group_name" => "default",
                                "group_priority" => 10,
                                "priority" => 10,
                                "detail" => "Check SSL/TLS mis-configuration which makes the communication between browser and server not secure, such as weak cipher, invalid certificate etc."})
  end

  def https_check(url)
    uri = URI(url)
    sch = uri.scheme
    if sch == 'https'
      return true
    elsif sch == 'http'
      return false
    end
  end

  def ssl_available_check
    time = 0
    if not https_check(@url)
      while time < 5
        if @url.end_with?("/")
          slash = true
        else
          slash = false
        end
        response =  Typhoeus::Request.new(@url, ssl_verifypeer: false, ssl_verifyhost: 1, connecttimeout:5,).run
        if response != nil && ((response.code >= 300 && response.code <= 303) || response.code == 307)
          response.response_headers.match(/^\s*Location\:\s*(.*?)$/i)
          if $1.start_with?('http')
            @url = $1
          else
            if $1.start_with?('/') && slash
                @url = @url.slice(0..-2) + $1
            elsif not ($1.start_with?('/') or slash)
              @url = @url + '/' + $1
            else
              @url = @url + $1
            end
          end
          if https_check(@url.delete!("\r"))
            break
          end
        else
          return false
        end
        time = time + 1
      end
    end

    begin
      response =  Typhoeus::Request.new(@url, ssl_verifypeer: false, ssl_verifyhost: 1, connecttimeout:5,).run
      if response != nil && response.code != 404 && response.code != 0
        return true
      end
    rescue => excep
      error
      Log.error(exp.to_s)
      Log.debug(exp.backtrace.join("\n"))
    end
    return false
  end

  def run
    begin
      Log.info("Checking SSL/TLS mis-configuration...")
      @config = @datastore['config']
      config = JSON.parse(@config, {create_additions:false})
      @url = config['target'].delete("\C-M")
      uri = URI(@url)
      if ssl_available_check == true
        @cert_file = "#{Revok::Config::MODULES_DIR}/ca-bundle.trust.crt"
        @url = @url.gsub("http://", "https://")
        init(@url,@cert_file)
        ssl_report = run_check
      else
        ssl_report = {ssl_available_check:["Target URL does not appear to support SSL.","Enable SSL for your site, or at least make sure the urls which transmit sensitive data are only accessible through secure HTTPS connections."]}
      end
    rescue => exp
      error
      Log.error(exp.to_s)
      Log.debug(exp.backtrace.join("\n"))
    ensure
      finalize
    end

    if ssl_report != nil && ssl_report.length > 0
      advise({"ssl_report" => ssl_report})
    else
      abstain
    end
    Log.info("SSL mis-configuration check completed")
  end
end
