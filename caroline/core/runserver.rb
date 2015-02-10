require_relative 'run'
require_relative 'framework'
require_relative 'dbms'
require_relative 'activemq'

module Revok

class RunServer
  def initialize
    @framework = Revok::Framework.new
    @framework.load_modules
    @framework.init_modules
  end

  def start
    @queue_client = Revok::ActiveMQClient.new
    @queue_client.connect
    @db_client = Revok::DBMS.new
    @db_client.connect
    active = true

    to_run = []
    begin
      while active do

        next unless active

        begin
          Log.info("Checking for test scans to be run...")
          run = get_run
          if run
            if(run['type'] == "list_modules")
              send_modules_list(run['id'])
              next
            end
            to_run << run
          end
        end

        to_run.each do |run|
          break unless active
          run_scan(run) if (save_run2db(run))
          to_run.delete(run)
        end
      end
    rescue => exp
      Log.error(exp.to_s)
      Log.debug(exp.backtrace.join("\n"))
    end

    clean_exit
  end

  def clean_exit
    Log.info("Goodbye, Caroline!")
    @framework = nil
    @queue_client.close
    @db_client.close
    exit(0)
  end

  private

    def get_run
      begin
        msg = @queue_client.connection.receive
        run = JSON.parse(msg.body, {create_additions:false})
        message_id = msg.headers['message-id']
        run = Revok::Run.new(run)
      rescue => exp
        Log.error(exp.to_s)
        Log.debug(exp.backtrace.join("\n"))
        run = nil
      end
      if run
        @queue_client.connection.ack(message_id)
      end
      return run
    end

    def send_modules_list(id = "")
      Log.info("Request modules list, preparing to send modules list")
      list = Array.new
      if (@framework)
        @framework.modules.each do |key, _module|
          if (!_module.info['required'])
            info = Hash.new
            info['name'] = key
            info['detail'] = _module.info['detail']
            list << info
          end
        end
      end
      msg = Hash.new
      msg['type'] = "modules_list"
      msg['id'] = id
      msg['list'] = list
      Log.info("Publishing modules list")
      @queue_client.publish(JSON.generate(msg).to_s)
    end

    def save_run2db(run)
      begin
        run_exists = @db_client.get_run(run['id'])
        if (!run_exists.empty?)
          Log.warn("Run #{run['id']} is existed, skipped")
          return false
        end
      rescue => exp
        Log.error(exp.to_s)
        Log.debug(exp.backtrace.join("\n"))
        return false
      end

      #remove sensitive data
      config = Base64.decode64(run['target_info'])
      config = JSON.parse(config, {create_additions:false})
      config.delete("username")
      config.delete("password")
      target_info = Base64.encode64(config.to_json)

      run['start_time'] = Time.now.to_i

      begin
        result = @db_client.put_run(run)
      rescue => exp
        Log.error(exp.to_s)
        Log.debug(exp.backtrace.join("\n"))
        result = false
      end
      return result
    end

    def run_scan(run)
      begin
        executor = Revok::ModuleExecutor.new(run, @framework.modules)
        if (run['modules'].include?('all'))
          executor.gen_exec_list_all
        else
          executor.gen_exec_list(run['modules'])
        end
        executor.execute
        @db_client.update_run_end_time(run['id'], Time.now.to_i)
      rescue => exp
        Log.error(exp.to_s)
        Log.debug(exp.backtrace.join("\n"))
      end
    end

end

end
