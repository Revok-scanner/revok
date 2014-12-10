#
# Cross-Origin Resource Sharing Module
# Check whether URLs allow access from other or all origins by sending crafted HTTP requests.
#
require 'webrick'
require 'stringio'
require 'json'
require 'core/module'
require "#{Revok::Config::MODULES_DIR}/lib/corss.rb.ut.rb"

class CorssChecker < Revok::Module
  include CORS
  def initialize(load_from_file = false, session_file = "")
    info_register("Cross-Origin_Resource_Sharing_Checker", {"group_name" => "default",
                              "group_priority" => 10,
                              "detail" => "Check whether URLs allow access from other or all origins by sending crafted HTTP requests.",
                              "priority" => 10})
    if (load_from_file)
      begin
        @session_data = File.open(session_file, 'r').read
      rescue => exp
        @session_data = ""
        Log.warn(exp.to_s)
        Log.debug(exp.backtrace.join("\n"))
      end
    end
  end

  def run
    @session_data = @datastore['session'] if @session_data == nil
    config = @datastore['config']
    begin
      data = JSON.parse(@session_data, {create_additions:false})
      config = JSON.parse(config, {create_additions:false})
      target = config['target']

      #delete duplicated requests
      uniq_tcks = del_dulp_reqs(data)

      #generate CORS requests
      req_hash = gen_cors_reqs(uniq_tcks, target, config, data)

      #send CORS requests and check the result headers
      Log.info( "Sending CORS requests and checking the result headers...")
      allow_oth, allow_all = send_cors_reqs(req_hash, data)
    rescue => exp
      Log.error(exp.to_s)
      Log.debug(exp.backtrace.join("\n"))
    end
    
    if allow_oth == "error" and allow_all == "error"
      error
    else
      allow_oth.uniq!
      allow_all.uniq!
      allow = allow_oth + allow_all
      allow.each do |al|
        if al.class == Array
          url = al.split(',')[0][0]
          dom = al.split(',')[0][1]
          list("#{url}",{'allowed_dom' => "#{dom}"})
        else
          list("#{al}")
        end
      end

      if allow_oth != []
        advise
      end

      if allow_all != []
        warn
      end

      if allow_oth == [] and allow_all == []
        abstain
      end
    end
    @session_data = nil
    Log.info("Cross-Origin resource sharing check completed")
  end
end
