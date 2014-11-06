require 'stomp'

class ActivemqHelper
  
  def initialize
     @login=ENV["AMPQ_USER"]
     @passcode=ENV["AMPQ_PASSWORD"]
     @host=ENV["AMPQ_HOST"]
     @port=ENV["AMPQ_PORT"].to_i
     @queue=ENV["AMPQ_QUEUE"]
     @cert_path="#{File.dirname(__FILE__)}/queue.pem"
     if @cert_path and File.exist?(@cert_path)
       @ssl=Stomp::SSLParams.new(ts_files:@cert_path) 
     else
       @ssl=false
     end
     @mutex=Mutex.new
  end
	
  def clean
    if @mqconn
      @mqconn.disconnect if not @mqconn.closed? 
    end
    @mqclient.close if @mqclient
  end
  
  def put(msg)
    @mutex.synchronize {
      self.client.publish(@queue, msg, {persistent:false,expires:(Time.now.to_i*1000)+(259200*1000),'amq-msg-type'=>'text'})
    }
  end

  def conn
    return @mqconn if @mqconn
    begin
      @mqconn=Stomp::Connection.new({
        :hosts =>[
        :login => @login, :passcode => @passcode, :host => @host, :port => @port, :ssl => @ssl
        ],
      })
      @mqconn.subscribe(@queue,{ack:'client'})
    rescue => exp
      p "#{$!}"
      p "#{exp.backtrace.join("\n")}"  
      @mqconn=nil
    end
    return @mqconn
  end
	
  def client
    return @mqclient if @mqclient
    begin
      @mqclient=Stomp::Client.new({
        :hosts =>[
          :login => @login, :passcode => @passcode, :host => @host, :port => @port, :ssl => @ssl
        ],
      })
    rescue => exp
      p "#{$!}"
      p "#{exp.backtrace.join("\n")}"  
      @mqclient=nil
    end
    return @mqclient
  end

  def close_conn
    @mqconn.disconnect if not @mqconn.closed?
  end

  def close_client
    @mqclient.close if @mqclient
  end	

end
