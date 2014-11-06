$ROOT_PATH=ENV['ROOT_PATH'] if not $ROOT_PATH
$: << "#{$ROOT_PATH}/db/"

require 'psqlHelper.rb'
require 'pg'


GET_TABLES="SELECT TABLENAME FROM pg_tables  WHERE TABLENAME = 'runcases';"
IMPORT_SCHEMA=File.open("#{File.dirname(__FILE__)}/revok.sql").read

#TESTING SQL
INSERTSQL="insert into runcases values (#{Random.new.rand(1...10000)},'----------',0,'','',0,0,'revok@example.com');"
SELECTSQL="select * from runcases;"

pgHelper=nil

begin
  puts"Connecting psql"
  pgHelper=PsqlHelper.new
rescue => exp
  puts $!
  puts "#{exp.backtrace.join("\n")}" 
  puts "connection failed!"
  pgHelper.clean if pgHelper
  exit
end

#import database schema
begin
  puts "Import data schema to database"

  begin
    pgHelper.conn.exec(IMPORT_SCHEMA)
  rescue =>exp
    if exp.to_s=~/already exist/
      puts "table exists,drop it and recreate?"
      puts "[y/n]"
      if STDIN.gets.upcase.chomp=="Y"
        pgHelper.conn.exec("BEGIN;")
        result=pgHelper.conn.exec(GET_TABLES)
        DROP_TABLES="DROP TABLE #{result.map{|x| x['tablename']}.join(',')};"
        pgHelper.conn.exec(DROP_TABLES)
        pgHelper.conn.exec(IMPORT_SCHEMA);

        #grant privileges
        result=pgHelper.conn.exec(GET_TABLES)
        REVOKE_PRI="REVOKE ALL on #{result.map{|x| x['tablename']}.join(',')} from PUBLIC;"
        pgHelper.conn.exec(REVOKE_PRI)
        pgHelper.conn.exec("COMMIT;")
        puts "Database initialization Finished."
      end
    else
      raise "Import dataschma error!"
    end
  end

  #confirm
  puts "Test database"
  pgHelper.conn.exec("BEGIN;")
  pgHelper.conn.exec(INSERTSQL)
  result=pgHelper.conn.exec(SELECTSQL)
  puts result[0] if result
  pgHelper.conn.exec("ROLLBACK;")
  puts "Success!"
rescue => exp
  puts $!
  pgHelper.conn.exec("ROLLBACK;") 
  puts "Database initialization faied."
ensure
  pgHelper.clean if pgHelper
end
