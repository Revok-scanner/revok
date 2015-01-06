require 'rubygems'
require 'base64'
require 'net/http'
require 'net/https'
require 'json'
require 'uri'
require 'nokogiri'
require 'mechanize'

$root = File.join(File.dirname(__FILE__), "/", "public")

$rest_username = "revok"
$rest_password = "password"

# Called by auto fill form module. It saves the login body. To avoid unexpected modify the global var, you should never modify it directly.
$login_msg = ""

$revok_http = lambda {
  uri = URI.parse("http://127.0.0.1:8443")
  http = Net::HTTP.new(uri.host, uri.port)
# If you want to enable SSL, make the below lines functional
#  http.use_ssl = true
#  http.ca_file = "revok.crt"
#  http.verify_mode = OpenSSL::SSL::VERIFY_PEER
  http
}

# Called by auto fill form module. To avoid unexpected modify the global var, you should always use this function to modify login_msg.
$set_login_msg = lambda { |msg|
    $login_msg = msg
}

# Called by auto fill form module. To avoid unexpected modify the global var, you should always use this function to load login_msg.
$get_login_msg = lambda {
    return $login_msg
}

# Called by auto fill form module. A callback(hook) function. It can capture the request before it be sent.
$capture_req = lambda { |agent, request|
    if request.method == "POST" && $get_login_msg.call == ""
      $set_login_msg.call(request.body)
    end
}

# Called by auto fill form module. It can find the login form and return the form object.
$find_form = lambda { |node|
    if node.name == "form"
      return node
    elsif node.name == "html"
      return nil
    else
      return $find_form.call(node.parent)
    end
}

map '/' do
  index = proc do |env|
    req = Rack::Request.new(env)
    index_file = File.join("#{$root}", "/", "index.html")
    if File.exists?(index_file) && (req.path_info == "/")
      req.path_info += "index.html"
    end
    Rack::Directory.new("#{$root}").call(env)
  end
  run index
end

map '/env' do
  env_ = proc do |env|
    begin
      req = Rack::Request.new env
      res = Rack::Response.new
      res.header['Content-Type'] = 'application/json'
      env.each do |key,val|
        res.write "#{key}: #{val}\n"
      end
    rescue =>exp
      res.write $!
      res.write "#{exp.backtrace.join("\n")}"
    end

    res.finish

  end
  run env_
end

map '/modules_list' do
  list_modules = proc do |env|
    begin
      req = Rack::Request.new env
      res = Rack::Response.new
      res.header['Content-Type'] = 'application/json'
      uid = `uuidgen`.chomp
      http = $revok_http[]
      request = Net::HTTP::Get.new("/moduleslist/#{uid}")
      request.basic_auth($rest_username, $rest_password)
      response = http.request(request)
      res.status = response.code
      res.write response.body
    rescue =>exp
      res.write $!
      res.write "#{exp.backtrace.join("\n")}"
    end
    res.finish
  end
  run list_modules
end

map '/scan' do
  scan = proc do |env|
    req = Rack::Request.new env
    res = Rack::Response.new
    res.header['Content-Type'] = 'application/json'
    begin
      config = JSON.parse(req.body.read, {:create_additions=>false})
      modules = config['modules']
      config = Base64.encode64(JSON.dump(config)).split("\n").join('')
      uid = `uuidgen`.chomp

      conf = <<-conf
{"id":"#{uid}","modules":#{modules},"target_info":"#{config}"}
conf

      http = $revok_http[]

      request = Net::HTTP::Put.new("/scans")
      request.basic_auth($rest_username, $rest_password)
      request.body = conf
      uid = '' if http.request(request).class != Net::HTTPCreated
      res.write JSON.dump({:uid=>uid})
    rescue =>exp
      res.write "Problem: #{$!}"
      res.write "#{exp.backtrace.join("\n")}"
    end
    res.finish
  end
  run scan
end

map '/screenshot' do
  screenshot = proc do |env|
    req = Rack::Request.new env
    res = Rack::Response.new
    res.header['Content-Type'] = 'application/json'
    begin
      case req.request_method
        when "POST"
          uid = `uuidgen`.chomp
          config = Base64.encode64(req.body.read).split("\n").join('')
          conf = <<-conf
{"id":"#{uid}","target_info":"#{config}", "modules":["Photographer"]}
conf

          http = $revok_http[]
          request = Net::HTTP::Put.new("/scans/#{uid}")
          request.basic_auth($rest_username, $rest_password)
          request.body = conf
          uid = '' if http.request(request).class != Net::HTTPCreated
          res.write JSON.dump({:uid=>uid})
        else
          uid = req['uid']
          uid = 'nil' if uid.nil?
          uid = '' if uid.size != 36
          http = $revok_http[]
          request = Net::HTTP::Get.new("/screenshot/#{uid}")
          request.basic_auth($rest_username, $rest_password)
          response = http.request(request)
          if response.class == Net::HTTPNotFound then
            res.status = 404;
            res.write "{}"
          else
            if response.body.match(/----screenshot\n(.*)\n----screenshot\n/)
              base64 = $1
            else
              base64=""
            end
            base64 = ['data:image/png;base64,',base64].join('')
            base64=base64.gsub(/----screenshot\n.*\n----screenshot\n/,'')
            report={"code"=>2,"result"=>"PASSED","pic"=>base64}
            res.write JSON.dump(report)
          end
      end
    rescue =>exp
      res.write "Problem: #{$!}"
      res.write "#{exp.backtrace.join("\n")}"
    end
    res.finish
  end
  run screenshot
end

map '/login_detect' do
  login_detect = proc do |env|
    req = Rack::Request.new env
    res = Rack::Response.new
    res.header['Content-Type'] = 'text/plain'
    result = Hash.new
    result['logtype'] = 'none'
    result['login'] = ''
    result['found'] = 'false'
    result['valid'] = 'true'
    begin
      target = JSON.parse(req.body.read, {:create_additions=>false})['target']
      result['login'] = target.to_s
      uri = URI.parse(target.to_s)
      http = Net::HTTP.new(uri.host, uri.port)
      http.open_timeout=5
      if uri.port == 443
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
      response = http.get("/" + uri.path)
      begin
        if response.code.to_i == 401
          result['logtype'] = 'basic'
          result['found'] = 'true'
          break
        elsif (response.code.to_i >= 300 && response.code.to_i <= 303) || response.code.to_i == 307
          if (response['Location'].to_s.include? 'http://') || (response['Location'].to_s.include? 'https://')
            uri = URI.parse(response['Location'].to_s)
            http = Net::HTTP.new(uri.host, uri.port)
            if uri.port == 443
              http.verify_mode = OpenSSL::SSL::VERIFY_NONE
              http.use_ssl = true
            end
            response = http.get("/" + uri.path)
          else
            uri.path = '/' if uri.path == ""
            path_list = uri.path.squeeze('/').split('/')
            path_list.push("") if path_list == []
            if uri.path[-1,1] == '/'
              path_list.push(response['Location'].to_s)
            else
              path_list[-1] = response['Location'].to_s
            end
            uri.path = path_list.join('/')
            response = http.get(uri.path)
          end
        else
          doc = Nokogiri::HTML(response.body)
          passwd_element = doc.css("input[type='password']")
          if !passwd_element.empty?
            result['login'] = uri.to_s
            result['logtype'] = 'normal'
            result['found'] = 'true'
            break
          else
            result['logtype'] = 'none'
            result['found'] = 'false'
            break
          end
        end
      end while true
      res.write JSON.dump(result)
    rescue =>exp
      result['valid'] = 'false'
      res.write JSON.dump(result)
      res.write "#{exp.backtrace.join("\n")}"
    end
    res.finish
  end
  run login_detect
end

# Auto fill login form module. It can be moved to backend if need
map '/login_fill' do
  login_fill = proc do |env|
    req = Rack::Request.new env
    res = Rack::Response.new
    res.header['Content-Type'] = 'application/json'
    result = Hash.new
    result['filled'] = "false"
    result['msg'] = ""
    $set_login_msg.call("")
    begin
      form = nil
      config = JSON.parse(req.body.read, {:create_additions=>false})
      login = config['login']
      username = config['username']
      passwd = config['password']
      agent = Mechanize.new
      agent.verify_mode = OpenSSL::SSL::VERIFY_NONE
      page = agent.get(login)
      doc = page.body
      doc = Nokogiri::HTML(doc)
      passwd_element = doc.css("input[type='password']")
      if !passwd_element.empty?
        form = $find_form.call(passwd_element[0])
      else
        raise ArgumentError, "Can not find password element!", caller
      end
      if form == nil
        raise ArgumentError, "Can not find any login form!", caller
      end
      result['filled'] = "true"
      res.write JSON.dump(result)
    rescue =>exp
      res.write JSON.dump(result)
      res.write "#{exp.backtrace.join("\n")}"
    end
    res.finish
  end
  run login_fill
end
