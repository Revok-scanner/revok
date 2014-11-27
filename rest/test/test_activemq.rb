$: << "#{File.dirname(__FILE__)}/../"
ENV["ROOT_PATH"] = "#{File.dirname(__FILE__)}/../../"
ENV["MSG_QUEUE_USER"] = "caroline"

require 'revok'
require 'activemq'

describe Revok::Rest::ActiveMQServer do

	before do
		@server = Revok::Rest::ActiveMQServer.new
	end

	it "can load config correctly" do
		@server.username.should == "caroline"
	end

end
