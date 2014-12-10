#
# HTTP Method Checking Module
# Check whether some HTTP methods such as 'TRACE' and 'OPTIONS' for URLS are available.
#
require 'net/http'
require 'json'
require 'core/module'

class MethodChecker < Revok::Module

  def initialize(load_from_file = false, session_file = "")
    info_register("HTTP_Method_Checker", {"group_name" => "default",
                              "group_priority" => 10,
                              "priority" => 10,
                              "detail" => "Check whether some HTTP methods such as 'TRACE' and 'OPTIONS' for URLS are available."})
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

  def method_check(uri)
    methods = Array.new()
    path = uri.path
    req_opt = Net::HTTPGenericRequest.new("OPTIONS", nil, nil, "#{path}")
    req_tra = Net::HTTPGenericRequest.new("TRACE", nil, nil, "#{path}")
    port =uri.port
    http = Net::HTTP.new(uri.host, port)
    if uri.scheme=='https'
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end
  
    response = http.request(req_opt)
    if (response.code != "405" && response.code != "501" && response.code != "403" && response.code != "400")
      if response['Allow'] != nil
        methods = response['Allow'].split(',')
        methods.delete_if {|item| (item == "GET") || (item == "POST") || (item == "HEAD") || (item == "PUT") || (item == "DELETE")}
        return methods
      end
    end

    response = http.request(req_tra)
    if (response.code == "200")
      methods.push("TRACE")
    end

    return methods
  end

  def run
    origin_urls = Array.new()
    issues = Array.new()
    result = true
    vul_paths = Hash.new()
    @session_data = @datastore['session'] if @session_data == nil
    begin
      data = JSON.parse(@session_data, {create_additions:false})
      @sitemap = data['sitemap']
      urls_list = @sitemap
      raise ArgumentError, "The sitemap is missing" if urls_list == nil

      #checking http method
      Log.info("Checking http methods for each directory...")
      urls_list.each {|url|
        uri = URI(url)
        if !uri.path.include?(".")
          methods = method_check(uri)
        else
          next
        end
        if (!methods.empty?)
          vul_paths[url] = methods.to_s.delete("[").delete("]").delete("\"")
          result = false
        end
      }
    rescue => exp
      issues.push(exp.to_s)
      result = false
    end

    if result
      abstain
    else
      if issues.size > 0
        issues.each do |issue|
          Log.error("#{issue}")
        end
        error
        return
      end
      if !vul_paths.empty?
        vul_paths.each_pair {|path, method|
          Log.warn("The URL \"#{path}\" should disable following methods:")
          Log.warn(method.to_s)
          list(path, {'method'=>"#{method}"})
        }
      end
      advise({"vul_paths" => vul_paths})
    end
    @session_data = nil
    Log.info("HTTP method check completed")

  end

end
