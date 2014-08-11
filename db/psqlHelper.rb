require 'pg'

class PsqlHelper

  def initialize
    @pgconn=nil
  end
  
  def clean
    @pgconn.close if @pgconn
  end

  def conn
    return @pgconn if @pgconn

    dbname=ENV["DB_NAME"]
    user=ENV["DB_USER"]
    password=ENV["DB_PASSWORD"]
    host=ENV["DB_HOST"]
    port=ENV["DB_PORT"].to_i

    @pgconn= PG::connect(:host=>host, :user=>user, :dbname=>dbname, :password=>password, :connect_timeout=>30, :port=>port)
  end

  def close
    @pgconn.close if @pgconn
  end

end
