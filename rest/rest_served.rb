require 'webrick'
require 'webrick/https'
require 'openssl'
require_relative 'revok'

# pkey = OpenSSL::PKey::RSA.new(File.open("#{REST_PATH}/revok.key",'r').read)
# cert = OpenSSL::X509::Certificate.new(File.open("#{REST_PATH}/revok.crt",'r').read)

s = WEBrick::HTTPServer.new(
  :Port => Revok::Rest::Config::PORT,
  :BindAddress => "0.0.0.0",
  :Logger => Revok::Rest::Log,
  :AccessLog => [
    [$stdout, Revok::Rest::Config::ACCESS_LOG_FORMAT]
  ]
# If you want to enable SSL, make the below lines functional
#  :SSLEnable => true,
#  :SSLCertificate => cert,
#  :SSLPrivateKey => pkey,
)

queue_client = Revok::Rest::ActiveMQClient.new
queue_client.connect
s.mount('/', Revok::Rest::APIServlet, queue_client)

['TERM','INT'].each do |signal|
  trap(signal) do
    s.shutdown
  end
end

s.start
