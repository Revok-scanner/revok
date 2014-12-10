#
# Redirection Module
# Check whether redirection of designed patterns exists in location of 30x response, refresh header, meta label or js.
#

require 'webrick'
require 'stringio'
require 'json'
require 'rex/socket'
require 'rex/proto/http'
require 'rex/text'
require 'digest'
require 'rex/proto/ntlm/crypt'
require 'rex/proto/ntlm/constants'
require 'rex/proto/ntlm/utils'
require 'rex/proto/ntlm/exceptions'

class RedirChecker < Revok::Module

  def initialize(load_from_file = false, session_file = "")
    info_register("Redirection", {"group_name" => "default",
                              "group_priority" => 10,
                              "priority" => 10,
                              "detail" => "Check whether redirection of designed patterns exists in location of 30x response, refresh header, meta label or js."})
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
    config = JSON.parse(@config, {create_additions:false})
    abstain
    @expected = "http://revok.example.com"
    payloads = [
      "http://revok.example.com",
      "://revok.example.com",
      "//revok.example.com",
      "revok.example.com",
      "HtTp://revok.example.com"
    ]
    @ev = ""
    
    def EV(*arg)
      @ev = "[Evidence] #{arg[0]}"
      Log.info @ev
    end

    def _30x_redir(resp)
      if resp.headers['location']!=nil
        if resp.headers['location'].downcase.start_with? @expected
          Log.info "Redir detected via location header"
          EV "Location: #{resp.headers['location']}"
          return true
        end
      end

      return false
    end

    def _refresh_redir(resp)
      # Refresh: 0;url=my_view_page.php
      if resp.headers['refresh']!=nil
        url = resp.headers['refresh'].split('=')[1]
        if url.start_with? @expected
          Log.info "Redir detected via refresh header"
          EV resp.headers['refresh']
          return true
        end
      end

      return false
    end

    def _meta_redir(resp)
      # <meta http-equiv="refresh" content="0; url=http://example.com/">

      resp.body.scan(/<meta.*url=([^"]*)/) do |matched|
        url = matched[0]
        if url.start_with? @expected
          Log.info "Redir detected via meta tag"
          #p resp.body[/<meta.*url.*>/]
          EV $~
          return true
        end
      end

      return false
    end

    def _js_redir(resp)
      # window.location="<%= @redir %>"

      script_re = /< *script.*>(.*)< *\/ *script *>/

      resp.body.gsub(/\r\n|\n/,'').scan(script_re) do |matched|
        matched[0].scan(/window\.location *= *"([^"]*)"/) do |matched_loc|
          url = matched_loc[0]

          if url.start_with? @expected
            Log.info "Redir detected via javascript"
            EV $~
            return true
          end
        end
      end

      return false
    end

    def add_warhead(missile, payload)
      warhead = missile.split('')
      if payload.size <= missile.size then
        payload.chars.each_with_index do |chr,idx|
          warhead[idx] = chr
        end
      end
      warhead = warhead.join('')
    end

    def get_user_inf_reqs
      #
      # Read session data and get user influenceable requests to be tested
      # output: 
      #   [{ :id => snks/id, :req => requests, :resp => responses, :tag => tag }, ...]
      #
      
      Log.info "Fetching requests to test from session data..."
      array = []
      @data['snks'].each do |tck,details|
        details['params'].each do |prm_tck|
          mimetype = "application/octet-stream"

          @data['snks'][tck]['srcs'].each do |src|
            new_hash = { 
              :id => details['id'], 
              :req => @data['requests'][src],
              :resp => @data['responses'][src],
              :tag => @data['tags'][prm_tck] 
            }
            array.push(new_hash)
          end
        end
      end
      array
    end
    
    def is_to_be_tested(h)
      # param: see an item of the hashes generated from get_user_inf_reqs
      # 
      # This method is to check first locally if an user influenceable request is related to open redirection
      #

      return true if not h[:resp]

      lmsg = h[:resp].downcase

      # find transactions whose response is 30x
      if lmsg.start_with?("http/1.1 30")
        return true
      end

      # refresh
      return true if lmsg[/refresh:/]

      # html meta tag
      return true if lmsg[/<meta.*url=([^"]*)/]

      # location in javascript
      return true if lmsg[/window\.location/]

      return false
    end
    @affected_urls = []

    ### NOTE: for local testing
    #json = File.read('/home/dev/test.json')
    #@data = JSON.parse(json)

    ### in revok 
    #@data = JSON.parse(datastore['SESSION'], {create_additions:false})
    begin
      @data = JSON.parse(@session_data, {create_additions:false})
      @config = JSON.parse(@config, {create_additions:false})
      if @data.nil?
        Log.error "datastore['SESSION'] is nil"
        return
      end
      uri=URI(@config['target'])
      host=uri.host
      port = uri.port
      context = {}
      ssl = (uri.scheme=='https'?true:false)
      ssl_version = nil
      proxies = nil
      conn = Rex::Proto::Http::Client.new(host, port, context, ssl, ssl_version, proxies)

      test_reqs = get_user_inf_reqs

      # p "Requests to be test are:"
      # p test_reqs.map{|x|x[]}

      test_reqs.each do |t|
        Log.info "Testing #{t[:id]}"
        id_report_done = false

        next if not is_to_be_tested(t)

        missile = t[:tag]

        payloads.each do |payload|
          warhead = add_warhead(missile, payload)

          #req = t[:req].gsub(missile,warhead)
          #NOTE: if tag is shorter than payload, the test goes wrong
          req = t[:req].gsub(missile,payload)
          if req[/Content-Length:.*/] != nil
            new_length = req[/Content-Length:.*/].sub('Content-Length: ','').to_i+payload.length-missile.length
            req = req.gsub(/Content-Length:.*/,"Content-Length: #{new_length}")
          end
          
          #p "Req to send: #{req}"

          begin
            resp = conn.send_recv(req,30)
          rescue => exp
            Log.error(exp.to_s)
            Log.debug(exp.backtrace.join("\n"))
          end

          if not resp
            #p "Error in resp"
            next
          end

          if _30x_redir(resp) or _refresh_redir(resp) or _meta_redir(resp) or _js_redir(resp)
            if not id_report_done
              id_report_done = true

              if req[0,3] == 'GET'
                @affected_urls.push [t[:id], 'GET']
              elsif req[0,4] == 'POST'
                @affected_urls.push [t[:id], 'POST']
              end
            end
          end
        end
      end 

      if not @affected_urls.empty?
        warn({'urls' => @affected_urls})
      end
    rescue => exp
      error
      Log.error(exp.to_s)
      Log.debug(exp.backtrace.join("\n"))
    end
    @session_data = nil
    Log.info("Redirection check completed")
  end
end
