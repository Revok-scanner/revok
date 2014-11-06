#
# Frame Burst Checking Module
# Check whether x-frame-options header is set.
#

$: << "#{File.dirname(__FILE__)}/lib/"
require 'report.ut'
require 'net/http'
require 'json'

class FrameBustingTester
  include ReportUtils
  def initialize(config=$datastore['config'],session_data=$datastore['session'],flag='s')
    @config=config
    if flag=='f'
      begin
        @session_data=File.open(session_data,'r').read 
      rescue =>exp
        log "ERROR: #{exp.to_s}" 
        @session_data=""
      end
    elsif flag=="s"
      @session_data=session_data
    else
      log 'unknow flag' 
      return nil
    end
  end

  def judge_block?
    yield
  end

  def url_uniq(a_urls)
    a_urls.uniq!
    urls = []
    path_param = Hash.new
    a_urls.each{|url|
      begin
        uri = URI(url)
      rescue URI::InvalidURIError
        next
      end
      if (!(uri.query == nil))
        params = []
        queries = URI::decode_www_form(uri.query)
        queries.each{|query|
          params << query[0]
        }
        if (path_param[uri.path] == nil)
          path_param[uri.path] = params
          urls << url
        end
      else
        urls << url
      end
    }
    return urls
  end

  def run
    vul_urls = Array.new()
    issues = Array.new()
    result = false
    log "Checking for X-Frame-Options header..."
    begin
      data = JSON.parse(@session_data, {create_additions:false})
      config = JSON.parse(@config, {create_additions:false})
      domain = URI(config['target']).host
      responses = data['responses']
      requests = data['requests']

      #Delete the non text/html type request-response pairs.
      responses.delete_if {|key, value|
        judge_block? do
          if (!value.include?("Content-Type: text/html") || !value.include?("HTTP/1.1 200\r\n"))
            # requests.delete_if {|key_r, value_r| key_r == key}
            break true
          else
            header_idx = value.index("\r\n\r\n")
            responses[key] = value[0, header_idx+4]
            url = /\b(https?|ftp|file):\/\/\S+/.match(requests[key])
            if (!url.to_s.include?(domain))
              # requests.delete(key)
              break true
            end
            break false
          end
        end
      }

      #Fliter the vulnerability URLs
      responses.each_pair {|number, header|
        #if (header.downcase.include?("x-frame-options: deny") || header.downcase.include?("x-frame-options: sameorigin"))
        if (header.scan(/x-frame-options: *deny|x-frame-options: sameorigin/i)!=[])
          next;
        #elsif (header.downcase.include?("frame-options: deny") || header.downcase.include?("frame-options: sameorigin"))
        elsif (header.scan(/frame-options: *deny|frame-options: *sameorigin/i)!=[])
          next;
        else
          url = /\b(https?|ftp|file):\/\/\S+/.match(requests[number])
          vul_urls.push(url.to_s)
        end
      }
      vul_urls = url_uniq(vul_urls)
      result = true if vul_urls.empty?
    rescue => exp
      issues.push(exp.to_s)
      result = false
    end

    if result
      abstain
    else
      #If any error happened, report here
      if issues.size > 0
        issues.each do |issue|
          log "ERROR: #{issue}" 
        end
        error
        return
      end
      if !vul_urls.empty?
        log "The following #{vul_urls.length.to_s} URLs miss the field \"X-Frame-Options\" in HTTP headers:" 
        vul_urls.each do |vul_url|
          log "URL: #{vul_url}" 
          list(vul_url)
        end
        advise({'vul_urls'=>vul_urls})
      else
        log "X-Frame-Options is set for all URLs"
      end
    end

  end
end
