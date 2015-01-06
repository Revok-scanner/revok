require 'io/console'
require 'json'
require 'webrick'
require 'stringio'
require_relative 'activemq'
require_relative 'run'

module Revok
module Rest

class APIServlet < WEBrick::HTTPServlet::AbstractServlet

  def initialize(server, queue_client)
    super server
    @queue_client = queue_client
  end

  def route(req, rsp)
    user = 'guest'
    WEBrick::HTTPAuth.basic_auth(req, rsp, Config::REALM_MESSAGE) do |usr, pw|
      user = usr
      usr == Config::USER and pw == Config::PASSWORD
    end

    @data = req.body
    @path = req.path
    @body = StringIO.new
    @code, @mime = 200, 'text/plain'

    @path =~ /(\/[a-z]*)/
    destination = "#{req.request_method}#{$1}"
    Log.debug("destination:")
    Log.debug(destination.class.name)
    Log.debug(destination.to_s)
    destination = {
      "PUT/scans" => :put_scan,
      #"GET/scans" => :get_scan,   #temporary disable
      "GET/screenshot" => :get_screenshot,
      #"GET/status" => :get_status,    #temporary disable
      "GET/moduleslist" => :get_modules_list
    }[destination]

    if not destination.nil?
      begin
        self.send(destination,)
      rescue => exp
        Log.error(exp.to_s)
        Log.debug(exp.backtrace.join("\n"))
        @body.truncate(0)
        @body.puts "500: Internal Server Error: #{$!}"
        @code, @mime = 500, 'text/plain'
      ensure
        @conn.close if @conn
      end
    else
      @body.puts "404: Not found."
      @code, @mime = 404, 'text/plain'
    end

    rsp.status = @code
    @body.rewind
    rsp.body = @body.read
    rsp['Content-Type'] = @mime
  end

  alias :do_GET :route
  alias :do_POST :route
  alias :do_PUT :route

  def put_scan
    success = false
    hash = JSON.parse(@data, {create_additions:false})

    run = Revok::Rest::Run.new(hash)
    run['type'] = "scan"
    msg = JSON.generate(run).to_s

    #if runCase && @runCaseServer.saveRunCaseToDB(runCase) && @runCaseServer.putRunCaseToQueue(runCase)

    if run && @queue_client.publish(msg)
      success = true
    end

    if success
      @code = 201
      @body.puts "201: OK"
    else
      @code = 409
      @body.puts "409: conflict"
    end

  end

  def get_scan
    @path =~ /\/scans\/([a-z0-9\-_]*)/
    id = $1

    runCase = @runCaseServer.loadRunCaseFromDBByID(id)

    if runCase.nil?
      @body.puts "404: Not found."
      @code, @mime = 404, 'text/plain'
    else
      @body.puts @runCaseServer.showRunCase(runCase)
      @code, @mime = 200, 'application/json'
    end

  end

  def get_modules_list
    Log.debug("invoke route moudles list")
    @path =~ /\/moduleslist\/([a-z0-9\-_]*)/
    id = $1
    raise RuntimeError if (id == "")
    msg = Hash.new
    msg['type'] = "list_modules"
    msg['id'] = id
    msg_back = nil
    begin
      msg = JSON.generate(msg).to_s
      @queue_client.publish(msg)
    rescue => exp
      Log.error(exp.to_s)
      Log.debug(exp.backtrace.join("\n"))
    end
    for i in 0..5
      msg_back = @queue_client.received_msg.select do |msg|
        body = JSON.parse(msg.body, {create_additions:false})
        body['id'] == id
      end
      if (!msg_back.empty?)
        @queue_client.received_msg.reject! do |msg|
          body = JSON.parse(msg.body, {create_additions:false})
          body['id'] == id && body['type'] == "modules_list"
        end
        Log.debug("Messages cache: #{@queue_client.received_msg}")
        begin
          msg_back = JSON.parse(msg_back.last.body, {create_additions:false})
          msg_back = msg_back['list']
          msg_back = JSON.generate(msg_back)
        rescue
          msg_back = nil
        end
        break
      else
        msg_back = nil
      end
      sleep(2)
    end
    if (msg_back)
      @body.puts msg_back
      @code, @mime = 200, 'application/json'
    else
      @body.puts "404: Not found."
      @code, @mime = 404, 'text/plain'
    end
  end

  def get_status
    @path =~ /\/status\/([a-z0-9\-_]*)/
    id = $1
    runCase = @runCaseServer.loadRunCaseFromDBByID(id)
    if runCase.nil?
      @body.puts "404: Not found."
      @code, @mime = 404, 'text/plain'
    else
      @body.puts @runCaseServer.showProcess(runCase)
      @code, @mime = 200, 'application/json'
    end

  end

  def get_screenshot
    @path =~ /\/reports\/([a-z0-9\-_]*)/
    id = $1

    msg_back = @queue_client.received_msg.select do |msg|
      body = JSON.parse(msg.body, {create_additions:false})
      body['id'] == id
    end
    if (!msg_back.empty?)
      @queue_client.received_msg.reject! do |msg|
        body = JSON.parse(msg.body, {create_additions:false})
        body['id'] == id && body['type'] == "screenshot"
      end
      Log.debug("Messages cache: #{@queue_client.received_msg}")
      begin
        msg_back = JSON.parse(msg_back.last.body, {create_additions:false})
        msg_back = msg_back['img']
      rescue
        msg_back = nil
      end
    else
      msg_back = nil
    end

    if (msg_back)
      @body.puts msg_back
      @code, @mime = 200, 'text/plain'
    else
      @body.puts "404: Not found."
      @code, @mime = 404, 'text/plain'
    end

  end

end

end
end
