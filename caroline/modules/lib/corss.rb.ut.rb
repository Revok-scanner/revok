require 'json'
require "net/https"
require "uri"

module CORS

  def filter_simple_req(req, tck)
    flg = true
    non_std = ['X-Requested-With: ', 'DNT: ', 'X-Forwarded-For: ', 'X-Forwarded-Proto: ', 'Front-End-Https: ', 'X-ATT-DeviceId: ', 'X-Wap-Profile: ', 'Proxy-Connection: ']
    plain_txt_1 = req.scan(/^Content-Type: application\/x-www-form-urlencoded(\r\n|; charset)/)
    plain_txt_2 = req.scan(/^Content-Type: text\/plain(\r\n|; charset)/)
    plain_txt_3 = req.scan(/^Content-Type: multipart\/form-data(\r\n|; charset)/)
    plain_txt_4 = Array.new()
    non_std.each do |nheader|
      re = req.scan(/^#{nheader}/)
      plain_txt_4.push re.to_s if re != []
    end

    flg = false if (plain_txt_1 == [] and plain_txt_2 == [] and plain_txt_3 == [] and plain_txt_4 == [])
    return "simple" if (req.scan(/^GET http.*?HTTP\//) != [] and plain_txt_4 == []) or (req.scan(/^HEAD http.*?HTTP\//) != [] and plain_txt_4 == []) or (req.scan(/^POST http.*?HTTP\//) != [] and flg)
    return "preflt"
  end

  def grab_origin(req,target)
    org_head = req.scan(/\r\nOrigin: (.*?)\r\n/)
    return true, "non" if org_head == []
    org_head = org_head[0][0]
    #return true if the header "Origin" is the same with the domain
    return true, "has" if target.scan(/#{org_head}/) != []
    return false, "non"
  end

  def grab_allow_header(resp)
    begin
      alw_dom = resp["access-control-allow-origin"]
    rescue
      alw_dom = resp.to_s.scan(/Access-Control-Allow-Origin: (.*?)\r\n/)
      alw_dom = alw_dom[0][0] if alw_dom != []
    end

    return "null" if alw_dom == [] or alw_dom == nil

    if alw_dom == "*"
      return "all"
    else
      return alw_dom
    end
  end

  def slct_param(param)
    p_arr = Array.new()
    param = param.split('&')
    param.each do |p|
      p_n = p.split('=')
      p_arr.push p_n[0]
    end
    return p_arr
  end

  def del_dulp_reqs(data)
    befr_uniq_urls = Hash.new()
    uniq_urls = Hash.new()
    uniq_tcks = Array.new()
    #delete the duplicated requests
    data['requests'].each do |tck, req|
      spl_url = []
      url = req.scan(/^(.*?) HTTP\//)
      next if url == []
      next if url[0][0].scan(/login/) != []
      spl_url = url[0][0].split('?')
      if spl_url.length > 1
        meth_dom = spl_url[0]
        params = spl_url[1]
        param_nm = slct_param(params)
        befr_uniq_urls[meth_dom] = [param_nm, tck]
      else
        meth_dom = spl_url[0]
        befr_uniq_urls[meth_dom] = [[], tck]
        next
      end
    end

    befr_uniq_urls.each do |k, v|
      flg = false
      if uniq_urls == {}
        uniq_urls[k] = v[0]
        uniq_tcks.push v[1]
        next
      else
        uniq_urls.each do |u,p|
          if u == k and p == v[0]
            break
          else
            flg = true
          end
        end
      end
      if flg
        uniq_urls[k] = v[0]
        uniq_tcks.push v[1]
      end
    end
    return uniq_tcks
  end

  def gen_cors_reqs(uniq_tcks, target, config, data)
    req_hash = Hash.new()
    resp_h = Array.new()

    logtype = config['logtype']
    username = config['username']
    password = config['password']
    domain = URI(config['target']).host
    cookie = data['cookie'].gsub("Cookie: ", "")

    uniq_tcks.each do |tck|
      req = data['requests'][tck]
      url = /\b(https?|ftp|file):\/\/\S+/.match(req)

      next if !(url.to_s.include?(domain))
      begin
        url = URI.escape(url.to_s)
        uri = URI.parse("#{url}")
      rescue
        Log.warn("Cannot parse URL: " + url.to_s)
        next
      end

      header_idx = req.index("\r\n\r\n")
      req = req[0, header_idx+4]

      same_org, has_org = grab_origin(req,target)
      res = filter_simple_req(req,tck)

      methd = req.scan(/^(.*?) http/)
      if methd != []
        methd = methd[0][0]
      else
        methd = 'GET'
      end

      if res == "preflt"
        request = Net::HTTP::Options.new(uri.request_uri)
        request.initialize_http_header({"User-Agent" => "Mozilla/5.0 (Unknown; Linux x86_64) AppleWebKit/534.34 (KHTML, like Gecko) PhantomJS/1.9.1 Safari/534.34", "Origin" => "http://www.example.com", "Access-Control-Request-Method" => methd, "Access-Control-Request-Headers" => "X-PINGOTHER", "Proxy-Connection" => "keep-alive", "X-PINGARUNER" => "pingpong", "Cookie" => cookie, "Accept" => "*/*"})
        request.basic_auth("#{username}", "#{password}") if logtype == "basic"
        same_org = true
      else
        if methd == "GET"
          request = Net::HTTP::Get.new(uri.request_uri)
        elsif methd == "POST"
          request = Net::HTTP::Post.new(uri.request_uri)
        else
          request = Net::HTTP::Head.new(uri.request_uri)
        end
        request.initialize_http_header({"User-Agent" => "Mozilla/5.0 (Unknown; Linux x86_64) AppleWebKit/534.34 (KHTML, like Gecko) PhantomJS/1.9.1 Safari/534.34", "Cookie" => cookie, "Accept" => "*/*", "Origin" => "http://www.example.com"})
        request.basic_auth("#{username}", "#{password}") if logtype == "basic"
      end

      #if the param "Origin" in header is in the same domain, need to re-send the request, else no need to
      if same_org
        req_hash[tck] = [request, uri]
      else
        req_hash[tck] = nil
      end
    end
    #puts req_hash
    return req_hash
  end
  
  def send_cors_reqs(req_hash, data)
    allow_all = Array.new()
    allow_oth = Array.new()
    
    n = 0
    len = req_hash.length

    req_hash.each do |tck, req|

      if req != nil
        uri = req[1]
        request = req[0]
        #puts "uri:  " + uri.to_s
        #puts "req:  " + req.to_s
        http = Net::HTTP.new(uri.host, uri.port)
        if uri.scheme=='https'
           http.use_ssl = true
           http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        end
        begin
          res = http.request(request)
        rescue
          Log.error("ERROR: #{tck.to_s} #{$!}")
          n = n + 1
          if n == len
            return "error", "error"
          end
        end
        #puts res.code
      else
        resp = data['responses'][tck]
        if resp.scan(/\r\n\r\n./) != []
          res = resp[0]
        else
          res = resp
        end
      end

      allow_dom = grab_allow_header(res) 
      if allow_dom == "all"
        url = data['requests'][tck].scan(/ (.*?) HTTP/)[0][0]
        allow_all.push url
      elsif allow_dom != "null" and allow_dom != nil
        url = data['requests'][tck].scan(/ (.*?) HTTP/)[0][0]
        allow_oth.push [url, allow_dom.to_s]
      end
    end
    return allow_oth, allow_all
  end

end
