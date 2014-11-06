$ROOT_PATH=ENV['ROOT_PATH']
$: << "#{$ROOT_PATH}/model/"

require 'model.Server.RunCase'
require 'io/console'
require 'json'
require 'pg'
require 'webrick'
require 'webrick/https'
require 'openssl'
require "open3"
require 'stringio'
require 'stomp'
require 'thread'
include WEBrick

REALM_MESSAGE = "caroline REST API authorization needed"
REST_PATH="#{$ROOT_PATH}/rest"
# pkey = OpenSSL::PKey::RSA.new(File.open("#{REST_PATH}/revok.key",'r').read)
# cert = OpenSSL::X509::Certificate.new(File.open("#{REST_PATH}/revok.crt",'r').read)

$rest_user=ENV["REST_USER"]
$rest_pass=ENV["REST_PASSWORD"]
port=ENV["REST_PORT"].to_i

s = HTTPServer.new(
  :Port => port,
  :BindAddress => "0.0.0.0"
# If you want to enable SSL, make the below lines functional
#  :SSLEnable => true,
#  :SSLCertificate => cert,
#  :SSLPrivateKey => pkey,
)

#adds a mimetype
#HTTPUtils::DefaultMimeTypes.store('rhtml', 'text/html')
$runCaseServer=RunCaseServer.new

class CarolineAPIServlet < HTTPServlet::AbstractServlet

  def initialize(server)
    super server
  end

  def route(req,rsp)
    @user = 'guest'
    HTTPAuth.basic_auth(req, rsp, REALM_MESSAGE) do |usr,pw|
      @user = usr
      usr == $rest_user and pw == $rest_pass
    end

    @data = req.body
    @path = req.path
    @body = StringIO.new
    @code,@mime = 200,'text/plain'

    @path =~ /(\/[a-z]*)/
    destination = "#{req.request_method}#{$1}"
    destination = {
      "PUT/scans" => :put_scan,
      "GET/scans" => :get_scan,
      "GET/reports" => :get_report,
      "GET/status" => :get_status,
    }[destination]

    if not destination.nil?
      begin
        self.send(destination,)
      rescue
        @body.truncate(0)
        @body.puts "500: Internal Server Error: #{$!}"
        @code,@mime = 500,'text/plain'
      ensure
        @conn.close if @conn
      end
    else
      @body.puts "404: Not found."
      @code,@mime = 404,'text/plain'
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
    success=false
    hash=JSON.parse(@data, {create_additions:false})

    if hash && hash['id'] && !$runCaseServer.exists?(hash['id'])
      runCase=$runCaseServer.createRunCase(hash)
    end

    if runCase && $runCaseServer.saveRunCaseToDB(runCase) && $runCaseServer.putRunCaseToQueue(runCase)
      success=true
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

    runCase=$runCaseServer.loadRunCaseFromDBByID(id)

    if runCase.nil?
      @body.puts "404: Not found."
      @code,@mime = 404,'text/plain'
    else
      @body.puts $runCaseServer.showRunCase(runCase)
      @code,@mime = 200,'application/json'
    end

  end

  def get_status
    @path =~ /\/status\/([a-z0-9\-_]*)/
    id = $1
    runCase=$runCaseServer.loadRunCaseFromDBByID(id)

    if runCase.nil?
      @body.puts "404: Not found."
      @code,@mime = 404,'text/plain'
    else
      @body.puts $runCaseServer.showProcess(runCase)
      @code,@mime = 200,'application/json'
    end

  end

  def get_report
    @path =~ /\/reports\/([a-z0-9\-_]*)/
    id = $1

    runCase=$runCaseServer.loadRunCaseFromDBByID(id)

    if runCase.nil? or runCase.log==""
      @body.puts "404: Not found."
      @code,@mime = 404,'text/plain'
    else
      @body.puts runCase.log
    end

  end

end

s.mount('/',CarolineAPIServlet)

['TERM','INT'].each do |signal|
  trap(signal) do
    begin
      t = Thread.new do
        $runCaseServer.clean
        $runCaseServer=nil
      end
      t.join
    rescue => exp
      puts exp.to_s
    end
    s.shutdown
  end
end

s.start
