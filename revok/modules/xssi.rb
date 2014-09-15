#
# Cross-site Scripting Checking module
# Inject dangerous characters ' "  < > and their encoded forms through parameters in HTTP request, then check whether these dangerous characters are filtered in the response.
#

$: << "#{File.dirname(__FILE__)}/lib/"

require 'report.ut'
require 'rex/socket'
require 'rex/proto/http'
require 'rex/text'
require 'digest'
require 'rex/proto/ntlm/crypt'
require 'rex/proto/ntlm/constants'
require 'rex/proto/ntlm/utils'
require 'rex/proto/ntlm/exceptions'
require 'json'

require 'patterns.rb.ut'


class XSSChecker
  include Patterns
  include ReportUtils

  def initialize(targetURL=$datastore['target'])
    uri=URI(targetURL)
    host=uri.host
    port = uri.port
    context = {}
    ssl = (uri.scheme=='https'?true:false)
    ssl_version = nil
    proxies = nil
    @conn=Rex::Proto::Http::Client.new(host,port, context, ssl, ssl_version, proxies)
    @target=targetURL
    if $datastore==nil or $datastore['session']==nil
      return nil
    end
  end
  
  def get_conn
    return @conn
  end
  
  def redirect? code
    [301, 302, 303, 307, 308].include?(code)
  end

  def run
    bad = Hash.new
    lists = Array.new
    checked = Array.new
    params = Array.new
    srcs = Array.new

    data = JSON.parse($datastore['session'],{create_additions:false})
    @cookie=data['cookie']
    log "Filtering requests to do xssi test..."

    patterns = PATTERNS
    dangers = ["'","\"","<",">"]
    counter = ('aaa'..'zzz').to_enum

    conn=get_conn

    data['snks'].each do |tck,details| 
      params += details['params']
      srcs += details['srcs']
    end
    params.uniq!
    srcs.uniq!
    patterns = PATTERNS[0,4] if srcs.size >5

    begin
      srcs.each do |src|
        ref = Hash.new
        req = data['requests'][src]
        req = req.gsub(/Cookie:.*\r\n/,"#{@cookie}\r\n")
        req_body = req.slice(req.index("\r\n\r\n")+4, req.size)
        req_url = req.lines.first.gsub(/HTTP.*?$/,"").strip
        url = req_url.gsub(/=[^&]*/,"=param")

        if not req_url.include? URI(@target).host then next end
        log "Checking: #{req_url}" 

        params.each do |prm_tck|
          threats = Array.new
          missile = data['tags'][prm_tck]
          # grab name of parameter
          if req_url.include? "=#{missile}"
            prm_k = req_url.scan(/([^&?]*)=#{missile}/)[0][0]
          elsif req_body.include? "=#{missile}"
            prm_k = req_body.scan(/([^&?]*)=#{missile}/)[0][0]
          else
            next
          end

          # avoid repeated injection
          next if checked.include? "#{url}; #{prm_k}"
          checked.push("#{url}; #{prm_k}")
          log "\tChecking param #{prm_tck}:" 

          patterns.each do |pat|
            bracket = counter.next
            payload = "#{bracket}#{pat}#{bracket}"
            warhead = missile.gsub(missile[0, payload.size], payload)
            req_sent = req.gsub(data['tags'][prm_tck],warhead)
            begin
              resp = conn.send_recv(req_sent,30)
            rescue
              log "ERROR: #{$!}" 
              next
            end

            #handle redirection
            if resp.code >= 300 && resp.code <= 307 && resp.headers['Location'].to_s != ""
              uri = resp.headers['Location'].to_s
              if not resp.headers['Location'].to_s.start_with?("/", "http")
                uri = "/" + resp.headers['Location'].to_s
              end
              req_sent = req_sent.gsub(req_url.gsub(data['tags'][prm_tck],warhead), "GET #{uri}")

              begin
                resp = conn.send_recv(req_sent,30)
              rescue
                log "ERROR: #{$!}" 
                next
              end
            end

            if resp != nil
              content = "#{resp.body}"
              content.scan(Regexp.new "#{bracket}.{1,1}#{bracket}").each do |mat|
                dangers.each {|dngr| if mat.include? dngr then threats << dngr end}
              end
            end
          end #end of patterns

          threats.uniq!
          log "\t\t#{threats.to_s}" if not threats.empty? 
          if threats.size > 0 then ref[prm_k] = threats end
        end #end of params

        if not ref.empty? then bad[url] = ref end
      end #end of srcs

    rescue => excep
      error
      log "ERROR: #{excep.to_s}" 
    end

    if not bad.empty?
      bad.each_pair do |k, v|
        details = "Details: "
        v.each_pair {|prm, dngr| details +="param=>#{prm}, unfiltered dangers=>#{dngr};"}
        lists.push("#{k.split(" ")[0]} request for #{k.split(" ")[1]}; #{details}")
      end
      lists.uniq!
      lists.each {|k| list(k)}
      warn
    else
      abstain
    end
    log "xssi is done"
  end

end
