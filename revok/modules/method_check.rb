#
# HTTP Method Checking Module
# Check whether some HTTP methods such as 'TRACE' and 'OPTIONS' for URLS are available.
#

$: << "#{File.dirname(__FILE__)}/lib/"
require 'report.ut'
require 'net/http'
require 'json'

class MethodCheckor
  include ReportUtils
  def initialize(session_data=$datastore['session'],flag='s')
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
      data = JSON.parse(@session_data, {create_additions:false})
      @sitemap=data['sitemap']
      urls_list = @sitemap
      raise ArgumentError, "Lack of the sitemap" if urls_list == nil

      #checking http method
      log "Checking each directory" 
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
      log exp.to_s 
      result = false
    end

    if result
      abstain
      log "RESULT: PASS" 
    else
      if issues.size > 0
        issues.each do |issue|
          log "\tIssue: #{issue}" 
        end
        error
        log "RESULT: ERROR" 
        return
      end
      if !vul_paths.empty?
        vul_paths.each_pair {|path, method|
          log "The URL \"#{path}\" should disable following methods:" 
          log method.to_s 
          list(path, {'method'=>"#{method}"})
        }
      end
      advise({"vul_paths" => vul_paths})
      log "RESULT: FAIL" 
    end

  end

end
