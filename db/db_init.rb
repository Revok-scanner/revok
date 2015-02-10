require 'sequel'

module Revok

class DBInit
  def initialize
    @database = nil
    @db_type = ENV['DB_TYPE']
  end

  def connect
    case @db_type
    when "sqlite"
      begin
        @database = Sequel.sqlite(ENV['DB_FILE'])
      rescue LoadError => exp
        FileUtils.touch("#{ENV['DB_FILE']}")
        retry
      end
    when "pgsql"
      @database = Sequel.postgres(ENV['DB_NAME'], :user => ENV['DB_USER'], :password => ENV['DB_PASSWORD'], :host => ENV['DB_HOST'], :port => ENV['DB_PORT'].to_i)

    else
      puts("Unknown database")
    end
  end

  def close
    @database.disconnect if @database
  end

  def create_table
    if (@database == nil)
      raise RuntimeError, "Invalid database connection", caller
    end

    @database.create_table? :run do
      String :id, :text => true, :null => false, :primary_key => true
      String :process, :text => true
      String :target_info, :text => true, :null => false
      Integer :start_time
      Integer :end_time
      String :requestor, :text => true
    end
  end
end

end

init = Revok::DBInit.new
init.connect
init.create_table
init.close
