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

end
