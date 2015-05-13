#
# Path Traversal Checking Module
# Check whether content of a file can be read by injecting its file path to requests.
#
require 'json'
require 'core/module'
require "#{Revok::Config::MODULES_DIR}/lib/path_traversal.rb.ut.rb"

class PathTraveler < Revok::Module
  include PATH_TRAV
  def initialize(load_from_file = false, session_file = "")
    info_register("Path_Traversal_Checker", {"group_name" => "default",
                              "group_priority" => 10,
                              "detail" => "Check whether content of a file can be read by injecting its file path to requests.",
                              "priority" => 10})
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
    @session_data = @datastore['session'] if @session_data == nil
    @config = @datastore['config']
    vul_url = Array.new()
    #Filter the URLs that have a parameter which is a file
    Log.info( "Filtering URLs with file parameters...")

    tcks, params = filter_url_request

    if tcks != {}
      #Perform path traversal against the URLs filtered above
      vul_url = path_trav(tcks, params)
    end

    if vul_url == "error"
      error
    elsif vul_url != []
      vul_url.each do |v|
        m = v[0]
        v = v[1].gsub(/\\/, "")
        list(v, 'mthd' => m)
      end
      warn
    else
      abstain
    end
    @session_data = nil
    Log.info("Path traversal check completed")
  end

  private

    def filter_url_request
      urls = Array.new
      @data = Hash.new()
      @uniq_url = Hash.new()
      @chk_list = Hash.new()
      @has_f_url = Array.new()
      @no_p_url = Array.new()

      @f_exts = FILEEXTS
      @f_name = ['doc','file','f','page','p','dir','filename','fname','target','msg']

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
      uri = URI(@target)
      host = uri.host
      port = uri.port
      context = {}
      ssl = (uri.scheme == 'https' ? true : false)
      ssl_version = nil
      proxies = nil
      conn = Rex::Proto::Http::Client.new(host, port, context, ssl, ssl_version, proxies)
      begin
        resp = conn.send_recv(req,30)
      rescue => exp
        Log.error(exp.to_s)
        Log.debug(exp.backtrace.join("\n"))
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
        @target = config['target']
        #Get the domain, because target may be many IPs or domains, so use target instead here
        target = config['target']
        domain = target.scan(/(http|https):\/\/(.*?)\//)
        if domain == []
          dom = target
        else
          dom = domain[0][0] + "://"  + domain[0][1]
        end

        Log.info("Now checking path traversal against URL: #{url}...")

        req = @data['requests'][v]
        mthd = req.scan(/^(.*?) /)[0][0]
        if mthd == "POST"
          req = req.sub(/\nContent-Length:.*/,"")
        end
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
            if resp != nil && ((resp.code >= 300 && resp.code <= 303) || resp.code == 307)
              uri = URI(resp['Location'])
              req_1 = req_1.gsub(/POST|GET.*?HTTP/, "GET #{uri} HTTP")
              resp = send_req(req_1)
            end
            time = time + 1
          end

          if resp != nil && resp.code != 200
            Log.info("'.' is not allowed in this URL.")
            next
          end

          #ToDo: replace with dot-slash patterns with different depth, e.g. ../etc/passwd, ../../../../etc/passwd, %2e%2e%2fetc%2fpasswd, ..\etc\passwd
          req_2 = req.gsub("=#{p}", "=/etc/passwd")
          resp = send_req(req_2)

          time = 0
          while time < 5
            if resp != nil && ((resp.code >= 300 && resp.code <= 303) || resp.code == 307)
              uri = URI(resp['Location'])
              req_2 = req_2.gsub(/POST|GET.*?HTTP/, "GET #{uri} HTTP")
              resp = send_req(req_2)
            end
            time = time + 1
          end

          flg = true if (resp != nil && resp.body.scan(/root:/) != [])
        end
        vul_url.push [mthd, url] if flg == true
      end

      return "error" if i == tcks.values.length
      return vul_url
    end

end
