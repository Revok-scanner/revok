module Utils
  
  def debug(message,type=0)
    log "debug"+message.to_s
  end
  
  def log(message,prefix=' [*] ',suffix='')
     output= prefix.to_s+message.to_s+suffix.to_s 
     $datastore['log']+="#{output}\n"
     puts output
  end
  
  def display_obj(obj)
    log "\n##############################\n" 
    log " obj public_methods: #{obj.public_methods}" 
    log " obj public_self_methods: #{obj.public_methods(false)}" 
    log " obj protected_methods: #{obj.protected_methods}" 
    log " obj private_methods: #{obj.private_methods}" 
    log " obj private_self_methods: #{obj.private_methods(false)}" 
    log "\n##############################\n" 
  end

  def cover(source_a,default_seting_file)
    composite = {}
    defalt_source=File.open(default_seting_file,'r').read 
    hash = JSON.parse(defalt_source.sub(/[^{]*/,''), {create_additions:false})
    hash.keys.each do |key| 
        composite[key] = hash[key]
    end
    return JSON.dump(composite).to_s if source_a==nil
    hash = JSON.parse(source_a.sub(/[^{]*/,''), {create_additions:false})
    hash.keys.each do |key| 
      composite[key] = hash[key]
    end
    return JSON.dump(composite).to_s
  end

  def merge(source_a,source_b)
    composite = {}
    hash = JSON.parse(source_a.sub(/[^{]*/,''), {create_additions:false})
    hash.keys.each do |key| 
        composite[key] = hash[key]
    end
    hash = JSON.parse(source_b.sub(/[^{]*/,''), {create_additions:false})
    hash.keys.each do |key| 
      composite[key] = hash[key]
    end
    return JSON.dump(composite).to_s
  end

  def fake_session
    injections = Hash.new
    tags = Hash.new
    ticks = Array.new
    tick = Hash.new
    walk = Hash.new
    requests = Hash.new
    response = Hash.new
    
    tags['02'] = "aaaaaaaa"
    
    tick['session'] = 1
    tick['url'] = "http://blackhole-1.iana.org"
    tick['depth'] = 0
    ticks.push(tick)
  
req = <<a_req
GET http://blackhole-1.iana.org HTTP/1.1\r\nUser-Agent: Mozilla/5.0 (Unknown; Linux x86_64) AppleWebKit/534.34 (KHTML, like Gecko) PhantomJS/1.9.1 Safari/534.34\r\nAccept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\r\nConnection: Keep-Alive\r\nAccept-Language: en-US,*\r\nHost: blackhole-1.iana.org\r\n\r\n
a_req
  
resp =<<a_resp
HTTP/1.1 500\r\nServer: nginx/1.2.9\r\nDate: Mon, 04 Nov 2013 08:43:52 GMT\r\nContent-Type: text/html\r\nConnection: close\r\n\r\n
a_resp
  
      requests["1"] = req
      response["1"] = resp
  
      injections['tags'] = tags
      injections['ticks'] = ticks
  
      walk['requests'] = requests
      walk['cookie'] = "Cookie: a_black_hole"
      walk['responses'] = response
      
      walk=JSON.dump(walk)
      injections=JSON.dump(injections)
      return [injections,walk]
  end

  def pretreated(flag,module_name=nil)
    if flag==0 or flag=="" or flag==nil
      return
    else
      log module_name,"\n** "," **"
      begin
        yield module_name
      rescue =>exp 
        log exp.to_s
      	if module_name.class == String
           log "ERROR: An issue occurred when running this module"
      	end
      end
    end
  end

  #===================================================#
  #                  DECHUNK FUNCTION                 #
  #===================================================#
  def dechunk(content)
    content = Array.new
    idx = 0
    while (idx < chunks.size)
      crlf = chunks.slice(idx,chunks.size).index("\r\n")
      num = chunks.slice(idx,crlf+2).to_i(16)
      break if num == 0
      chunk = chunks.slice(idx+crlf+2,num)
      content << chunk
      idx = idx+crlf+2+num+2
    end
    return content.join('')
  end
end
