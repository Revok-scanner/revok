#
# SQL Injection Checking Module
# Inject malicious SQLs to HTTP requests, then check keywords from responses or the response time to find out potential SQL injection vulnerability.
#

require 'json'
require 'open-uri'
require 'rex/socket'
require 'rex/proto/http'
require 'rex/text'
require 'rex/compat'
require 'digest'
require 'rex/proto/ntlm/crypt'
require 'rex/proto/ntlm/constants'
require 'rex/proto/ntlm/utils'
require 'rex/proto/ntlm/exceptions'
require 'core/module'
require "#{Revok::Config::MODULES_DIR}/lib/Approach1.rb.ut.rb"

class SQLiChecker < Revok::Module
  include Approach1

  def initialize(load_from_file = false, session_file = "")
    info_register("SQL_Injection_Checker", {"group_name" => "default",
                              "group_priority" => 10,
                              "priority" => 10,
                              "detail" => "Inject malicious SQLs to HTTP requests, then check keywords from responses or the response time to find out potential SQL injection vulnerability."})
    
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
    @config = @datastore['config']
    @session_data = @datastore['session'] if @session_data == nil
    aResultE,aResultT,aResult,aFinal = Array.new,Array.new,Array.new,Array.new
    aIssues = Array.new
    result = true

    begin
      @config=JSON.parse(@config, {create_additions:false})
      @session = JSON.parse(@session_data, {create_additions:false})
      Log.info("Error based testing...")
      begin
        aResultE = fErrorBased
      rescue => exp
        Log.error("Exception in Error-Based Test:")
        Log.debug("#{exp.backtrace.join("\n")}")
        aResultE = Array.new
      end

      Log.info("Time based testing...")
      begin
        aResultT = fTimeBased(aResultE)
      rescue => exp
        Log.error("Exception in Time-Based Test:")
        Log.debug(exp.backtrace.join("\n"))
        aResultT = Array.new
      end
      aResult = aResultE + aResultT
      #Cleaning up loop
      aResult.each do |value|
        repeated = false
        aFinal.each do |val|
          if(value[/GET.*\?/] and value[/GET.*\?/]==val[/GET.*\?/]) or (value[/POST.*HTTP/] and value[/POST.*HTTP/]==val[/POST.*HTTP/])
            repeated = true
            break
          end
        end
        if repeated == false then aFinal.push(value) end
      end
    rescue Timeout::Error
      Log.error("Timeout error.")
    rescue => exp
      aIssues.push(exp.to_s)
      result = false
    end

    #p "Print vulnerabilities."
    #aFinal.each {|value| p " ----------------------#{value.key}-------------------\n\n#{value}"}
    result = false if !aFinal.empty?

    if result
      abstain
    else
      if aIssues.size > 0
        aIssues.each do |issue|
          Log.error("#{issue}")
        end
        error
        @session_data = nil
        return
      end
      hUrls = Hash.new
      aFinal.each do |value|
        method = ""
        url = /\b(https?|ftp|file):\/\/\S+/.match(value.to_s)
        if value.to_s.include? "GET"
          method = "GET"
        elsif value.to_s.include? "POST"
          method = "POST"
        end
        hUrls[url] = method
        list(url, {'method'=>"#{method}"})
      end
      warn({'vul_urls' => hUrls})
    end
    @session_data = nil
    Log.info("SQL injection check completed")
  end


  #===================================================#
  #              ERROR BASED INJECTION                #
  #===================================================#
  def fErrorBased
    appr1,hReq = Approach1::ParametrizeErrorBasedURL.new,Hash.new
    result = "FAIL"
    aAllRequests,hOriReq,aURL,i,cnt = getreq,get_original_req,geturl,0,0
    aResponses = Array.new
    aKeywords = appr1.getkeywords
    aURL.each do |url|
      aAllRequests.each do |value|
        if !hReq[value] and value[/#{url}.* HTTP/]
          hReq[value],i = i,i+1
          break
        end
      end
    end
    hReq = hReq.invert
    hReq = appr1.paraURL(hReq)
    
    uri=URI(@config['target'])
    host=uri.host
    port = uri.port
    context = {}
    ssl = (uri.scheme=='https'?true:false)
    ssl_version = nil
    proxies = nil
    conn=Rex::Proto::Http::Client.new(host,port, context, ssl, ssl_version, proxies)
    cnt = 0

    #INJECTED SQL
    hReq.each do |j,req|
      class << hReq[j]
      attr_accessor :id
      end
      hOriReq.each do |key,value|
        if value[/GET.*\?/] and value[/GET.*\?/] == req[/GET.*\?/] then
          hReq[j].id = key
          break
        end
        if value[/POST.*HTTP/] and value[/POST.*HTTP/] == req[/POST.*HTTP/] and value[/Content-Length:.*/]==req[/Content-Length:.*/]
          difference = req.length-value.length
          new_length = req[/Content-Length:.*/].sub('Content-Length: ','').to_i+difference
          req = req.sub(/Content-Length:.*/,"Content-Length: #{new_length}")
          hReq[j].id = key
          break
        end
      end
      next if hReq[j].id == nil

      resp = conn.send_recv(req,30)

      if resp != nil
        content = "#{resp.body}"
        aKeywords.each_with_index do |keyword,index|
          if content[keyword] and !content[/AND/] then
            Log.info("Keyword found: " << keyword.to_s[/\)\w*\[/].slice(1..-2))
            aResponses[cnt] = req
            class << aResponses[cnt]
              attr_accessor :key
            end
            aResponses[cnt].key = hReq[j].id
            cnt += 1
          end
        end
      end
    end
    return aResponses
  end


  #===================================================#
  #              GET REQUEST FUNCTION                 #
  #===================================================#
  def getreq
    hReqwTag,hFinal,appr1 = Hash.new,Hash.new,Approach1::ParametrizeErrorBasedURL.new
    temp = Array.new
    j = @session
    j['requests'].each {|key,value| hReqwTag[value] = key}
    #PREVENT FALSE+  
    hReqwTag = hReqwTag.invert
    j['responses'].each do |key,resp|
      appr1.getkeywords.each do |keyword|
        if resp[keyword] then hReqwTag.delete(key) end
      end
    end
    hReqwTag = hReqwTag.invert
      
    hTags = j['tags'].invert
    hReqwTag.each_key {|key| temp.push(key)}
    hTags.each_key do |tag|
      temp.each_with_index do |elem,index|
        body = elem.gsub(elem.split("\r\n\r\n")[0], "")
        if elem.lines.first[tag] or body[tag] then temp[index] = elem.gsub(tag,'X_param_X') end
      end
    end
    i = 0
    temp.each do |elem|
      if elem['X_param_X'] and !hFinal[elem] then
        hFinal[elem] = i
        i+=1
      end
    end
    aFinal = hFinal.keys.to_a
    return aFinal
  end


  #===================================================#
  #                GET URL FUNCTION                   #
  #===================================================#
  def geturl
    hURLwVar,hFinal = Hash.new,Hash.new
    temp = Array.new
    j = @session
    j['requests'].each do |key,value|
      if value[/[h].* HTTP\//].slice(0..-7) then
        url = value[/[h].* HTTP\//].slice(0..-7).sub(/\?.*/,'')
        hURLwVar[url] = key
      end
    end
    i = 0
    hURLwVar.each_key do |key|
      if !hFinal[key] then
        hFinal[key] = i
        i+=1
      end
    end
    aFinal = hFinal.keys.to_a
    return aFinal
  end

  
  #===================================================#
  #          GET ORIGINAL REQUEST FUNCTION            #
  #===================================================#
  def get_original_req
    hReqwTag = Hash.new
    j = @session
    elem = 'requests'
      j[elem].each do |key,value|
          hReqwTag[value] = key
      end
      hTags = j['tags'].invert
      hReqwTag = hReqwTag.invert
      hTags.each_key do |tag|
        hReqwTag.each do |key,elem|
          if elem[tag] then
            hReqwTag[key] = elem
          end
        end
      end
    return hReqwTag
  end


  #===================================================#
  #               TIME BASED INJECTION                #
  #===================================================#
  def fTimeBased aErrorBased
    appr1,hReq,hReqi,otime,itime,iprob = Approach1::ParametrizeTimeBasedURL.new,Hash.new,Hash.new,Array.new,Array.new,0.5
    result,aResponses = "FAIL",Array.new
    aAllRequests,hOriReq,aURL,i,cnt = timegetreq,get_original_req,geturl,0,0
    
    if aErrorBased.length > 0 then
      aURL.each do |url|
        aAllRequests.each_with_index do |value,index|
          if !hReq[value] and value[/#{url}.* HTTP/] and !(aErrorBased[index].to_s[/#{url}.* HTTP/]) then
            hReq[value],i = i,i+1
            break
          end
        end
      end
    else
      aURL.each do |url|
        aAllRequests.each do |value|
          if !hReq[value] and value[/#{url}.* HTTP/]
            hReq[value],i = i,i+1
            break
          end
        end
      end
    end

    hReq = hReq.invert
    hReqi = appr1.paraURL(hReq)
    uri=URI(@config['target'])
    host=uri.host
    port = uri.port
    context = {}
    ssl = (uri.scheme=='https'?true:false)
    ssl_version = nil
    proxies = nil
    conn=Rex::Proto::Http::Client.new(host,port, context, ssl, ssl_version, proxies)

    #ORIGINAL REQS
    i = 0
    hReq.each do |key,req|
      hOriReq.each do |key,value|
        if value[/POST.*HTTP/] and value[/POST.*HTTP/] == req[/POST.*HTTP/] and value[/Content-Length:.*/]==req[/Content-Length:.*/]
          difference = req.length-value.length
          new_length = req[/Content-Length:.*/].sub('Content-Length: ','').to_i+difference
          req = req.sub(/Content-Length:.*/,"Content-Length: #{new_length}")
          break
        end
      end
      ini = Time.now.to_f
      resp = conn.send_recv(req,30)
      ini_1=Time.now.to_f
      interval_1=ini_1 - ini
      resp = conn.send_recv(req,30)
      ini_2=Time.now.to_f
      interval_2=ini_2 - ini_1
      if interval_2>0.6 * interval_1 && interval_2 < 1.4 * interval_1
        otime[i] = (ini_2 - ini) * 0.5
      else
        resp = conn.send_recv(req,30)
        resp = conn.send_recv(req,30)
        resp = conn.send_recv(req,30)
        otime[i] = (Time.now.to_f - ini) * 0.2
      end
      i+=1
    end

    #INJECTED SQL
    i = 0
    hReqi.each do |j,req|
      class << hReqi[j]
        attr_accessor :id
      end
      hOriReq.each do |key,value|
        #Add the original key from the JSON file as attribute to save it
        if value[/GET.*\?/] and value[/GET.*\?/] == req[/GET.*\?/] then
          hReqi[j].id = key
          break
        end
        if value[/POST.*HTTP/] and value[/POST.*HTTP/]==req[/POST.*HTTP/] and value[/Content-Length:.*/]==req[/Content-Length:.*/]
          difference = req.length-value.length
          new_length = req[/Content-Length:.*/].sub('Content-Length: ','').to_i+difference
          req = req.sub(/Content-Length:.*/,"Content-Length: #{new_length}")
          hReqi[j].id = key
          break
        end
      end
      next if hReqi[j].id == nil

      ini = Time.now.to_f
      resp = conn.send_recv(req,30)
      ini_1=Time.now.to_f  
      interval_1=ini_1 - ini
      if  interval_1 > 10*otime[i] && interval_1 > 5
        itime[i] = interval_1
      else
        conn.send_recv(req,30)
        ini_2=Time.now.to_f
        interval_2=ini_2 - ini_1
        if interval_2>0.6 * interval_1 && interval_2 < 1.4 * interval_1
          itime[i] = (ini_2 - ini) * 0.5
        else
          resp = conn.send_recv(req,30)
          resp = conn.send_recv(req,30)
          resp = conn.send_recv(req,30)
          resp = conn.send_recv(req,30)
          itime[i] = (Time.now.to_f - ini) * 0.2
        end
      end
      if itime[i] - otime[i] > 5 || (itime[i]-otime[i] > 1 &&otime[i] < 0.1)
      aResponses[cnt] = req
        class << aResponses[cnt]
          attr_accessor :key
        end
        aResponses[cnt].key = hReqi[j].id
        cnt += 1
      end
      i+=1
    end
    return aResponses
  end
  
  def timegetreq
    hReqwTag,hFinal = Hash.new,Hash.new
    temp = Array.new
    j = @session
    j['requests'].each do |key,value|
      hReqwTag[value] = key
    end
    hTags = j['tags'].invert
    hReqwTag.each_key {|key| temp.push(key)}
    hTags.each_key do |tag|
      temp.each_with_index do |elem,index|
        body = elem.gsub(elem.split("\r\n\r\n")[0], "")
        if elem.lines.first[tag] or body[tag] then temp[index] = elem.gsub(tag,'X_param_X') end
      end
    end
    i = 0
    temp.each do |elem|
      if elem['X_param_X'] and !hFinal[elem] then
        hFinal[elem] = i
        i+=1
      end
    end
    aFinal = hFinal.keys.to_a
    return aFinal
  end

end
