#
# HTTP Method Checking Module
# Check whether some HTTP methods such as 'TRACE' and 'OPTIONS' for URLS are available.
#
require 'net/http'
require 'json'
require 'core/module'
require "#{Revok::Config::MODULES_DIR}/lib/report.ut.rb"

class MethodCheckor < Revok::Module
  include ReportUtils
  def initialize(load_from_file = false, session_file = "")
    info_register("MethodCheckor", {"group_name" => "default",
                              "group_priority" => 10,
                              "priority" => 10})
    if(load_from_file)
      begin
        @session_data = File.open(session_file, 'r').read
      rescue => exp
        @session_data = ""
        Log.warn(exp.to_s)
        Log.debug("#{exp.backtrace}")
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
    begin
      @session_data = @datastore['session'] if @session_data == nil
      data = JSON.parse(@session_data, {create_additions:false})
      @sitemap=data['sitemap']
      urls_list = @sitemap
      if urls_list == nil then
         Log.error("Lack of the sitemap" )
         return 
      end 

      #checking http method
      Log.info( "Checking http methods for each directory..." )
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
      Log.warn("The result is none")
    else
      if issues.size > 0
        issues.each do |issue|
          Log.error( "#{issue}" )
        end
        error
        return
      end
      if !vul_paths.empty?
        vul_paths.each_pair {|path, method|
          Log.info( "The URL \"#{path}\" should disable following methods:" )
          Log.warn( method.to_s )
          list(path, {'method'=>"#{method}"})
        }
      end
      advise({"vul_paths" => vul_paths})
    end
  end

end
