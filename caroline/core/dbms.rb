require 'sequel'
require_relative 'run'

module Revok

class DBMS
  def initialize
    @database = nil
    @db_type = Config::DB_TYPE
  end

  def connect
    case @db_type
    when "sqlite"
      @database = Sequel.sqlite(Config::DB_FILE)
    when "pgsql"
      @database = Sequel.postgres(Config::DB_NAME, :user => Config::DB_USER, :password => Config::DB_PASSWORD, :host => Config::DB_HOST, :port => Config::DB_PORT, :sslmode => Config::DB_SSL)
    else
      Log.error("Unknown database")
    end
  end

  def close
    @database.disconnect if @database
  end

  def put_run(run)
    if (@database == nil)
      raise RuntimeError, "Invalid database connection", caller
    end

    #query = 'insert into run(id,process,scan_config,target_info,start_time,end_time,requestor) values(?, ?, ?, ?, ?, ?, ?)'
    #param = {run['id'] => "1",run['process'] => "2",run['scan_config'] => "3",run['target_info'] => "4",run['start_time'] => "5",run['end_time'] => "6",run['requestor'] => "7"}
    #result = @database.execute(query, param)

    result = @database[:run].insert(:id => run['id'],
                                    :process => run['process'],
                                    :target_info => run['target_info'],
                                    :start_time => run['start_time'],
                                    :end_time => run['end_time'],
                                    :requestor => run['requestor'])
    return result
  end

  def update_run_end_time(id, timestamp)
    if (id_check(id) && timestamp.class.name == "Fixnum")
      rec = @database[:run].filter(:id => id)
      rec.update(:end_time => timestamp)
    else
      raise ArgumentError, "#{self.class.name}: Invalid uuid or timestamp", caller
    end
  end

  def get_run(id)
    #query = "SELECT id FROM run WHERE id = '#{id}';"
    if (id_check(id))
      result = @database[:run].filter(:id => id)
      return result
    else
      raise ArgumentError, "#{self.class.name}: Invalid uuid", caller
    end
  end

  attr_accessor   :db_type

  private
    def id_check(id)
      id = /^[0-9a-z]{8}-[0-9a-z]{4}-[0-9a-z]{4}-[0-9a-z]{4}-[0-9a-z]{12}$/.match(id)
      return id[0] if (id != nil)
    end
end

end
