require 'sqlite3'

module Revok

class SQLiteClient
  def initialize
    @database = nil
  end

  def connect(file_path)
    begin
      @database = SQLite3::Database.new(file_path)
    rescue => exp
      Log.error("Connecting to database failed: " + exp.to_s)
      Log.debug(exp.backtrace.join("\n"))
      self.close
      @database = nil
    end

    return @database
  end

  def close
    @database.close if @database
  end

  def execute(query)
    if (@database == nil)
      Log.error("Invalid database connection")
      return false
    end

    begin
      @database.execute(query)
    rescue => exp
      Log.error(exp.to_s)
      Log.debug(exp.backtrace.join("\n"))
      return false
    end

    return true
  end

  attr_reader   :database
end

end
