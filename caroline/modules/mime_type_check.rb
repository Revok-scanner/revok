#
# MIME Type Checking Module
# Check whether nosniff header is set. And find reponses whose actual contect type is mismatched with the defined one.
#
require 'base64'
require 'nokogiri'
require 'rkelly'
require 'json'
require 'net/http'
require 'core/module'

class MimeTypeChecker < Revok::Module

  def initialize(load_from_file = false, session_file = "")
    info_register("MIME_Type_Checker", {"group_name" => "default",
                              "group_priority" => 10,
                              "priority" => 10,
                              "detail" => "Check whether nosniff header is set. And find reponses whose actual contect type is mismatched with the defined one."})
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

  def detect_html(resp_body)
    html = ['<!DOCTYPE HTML', '<HTML', '<BODY', '<SCRIPT', '<A', '<IFRAME', '<DIV', '<TABLE', '<IMG']
    html.each do |k|
      if resp_body.scan(/#{k}/i)==[]
        next
      else
        return true 
      end
    end
    return false
  end

  def detect_xml(resp_body)
    error = Nokogiri::XML.parse(resp_body).errors
    if error == []
      return true
    else
      return false
    end
  end

  def detect_js(resp_body)
    begin
      parser = RKelly::Parser.new
      js = parser.parse(resp_body)
    rescue SyntaxError => error
      return false
    rescue => error
      return true
    end
    return true
  end

  def detect_json(resp_body)
    begin
      JSON.parse(resp_body)
    rescue  => error
      return false
    end
    return true
  end

  def check_mismatch(req, resp)
    index = resp.index("\r\n\r\n")
    resp_body = resp[index+4, resp.length-1]
    return if resp_body == ""

    content_type = /\r\n(Content-Type:.*?)\r\n/.match(resp).to_s.strip

    if content_type.include? "text/html" and detect_html(resp_body) == false
      Log.warn("Actual content type mismatchs with html: #{req}")
    elsif content_type.scan(/\/xml/) != [] and detect_xml(resp_body) == false
      Log.warn("Actual content type mismatchs with xml: #{req}")
    elsif content_type.scan(/\/javascript|\/x-javascript/)!=[] and detect_js(resp_body) == false
      Log.warn("Actual content type mismatchs with javascript: #{req}")
    elsif content_type.scan(/\/json/) != [] and detect_json(resp_body) == false
      Log.warn("Actual content type mismatchs with json: #{req}")
    elsif content_type.include? "text/plain" and detect_html(resp_body)|detect_js(resp_body)|detect_xml(resp_body)|detect_json(resp_body) == true
      Log.warn("Actual content type mismatchs with plain: #{req}")
    else
      return
    end
    @mismatch_report.push(req)
  end

  def run
    @session_data = @datastore['session'] if @session_data == nil
    config = @datastore['config']
    sniff_urls = Array.new()
    report = Array.new()
    @mismatch_report = Array.new()
    aff_url = String.new

    Log.info("Checking for nosniff header and mismatched content type...")
    begin
      session = JSON.parse(@session_data, {create_additions:false})
      config = JSON.parse(config, {create_additions:false})
      requests = session['requests']
      responses = session['responses']
      domain = URI(config['target']).host

      responses.each do |v, k|
        resp_header = k.split("\r\n\r\n")[0]
        next if !resp_header.include?("HTTP/1.1 200")
        if resp_header.scan(/Content-Type:/i)==[] or resp_header.scan(/X-Content-Type-Options: *nosniff/i)!=[]
          next
        else
          url = requests[v].split("\r\n")[0].gsub(/HTTP\/1.*/, "").gsub(/=[^&]*/,"=param")
          if url.include? domain
            sniff_urls.push(url)
            check_mismatch(url, k)
          end
        end
      end

      sniff_urls.each {|k| k.gsub(/=[^&]*/,"=param")}
      sniff_urls = sniff_urls.uniq.sort
      sniff_urls.each do |k|
        #p("URL without nosniff header: #{k}")
      end

      @mismatch_report = @mismatch_report.uniq
      sniff_urls.unshift("URLs without nosniff response header. Number of pages: #{sniff_urls.size}") if sniff_urls != []
      @mismatch_report.unshift("Actual content type is mismatched with Content-Type header. Number of pages: #{@mismatch_report.size}") if @mismatch_report != []
      report = sniff_urls + @mismatch_report
    rescue => exp
      error
      Log.error(exp.to_s)
      Log.debug(exp.backtrace.join("\n"))
    end

    if report == []
      abstain
    else
      report.each do |k|
        k = k.gsub(/POST/, "POST request for").gsub(/GET/, "GET request for")
        list("#{k}")
      end
      num = @mismatch_report.size + sniff_urls.size
      num = num - 1 if @mismatch_report.size != 0
      num = num - 1 if sniff_urls.size != 0
      advise({ "num" => num })
    end
    @session_data = nil
    Log.info("MIME type check completed")
  end
end
