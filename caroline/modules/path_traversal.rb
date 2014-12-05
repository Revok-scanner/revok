#
# Path Traversal Checking Module
# Check whether content of a file can be read by injecting its file path to requests.
#
require 'json'
require 'core/module'
require "#{Revok::Config::MODULES_DIR}/lib/path_traversal.rb.ut.rb"

class PathTraveler < Revok::Module
  include PATH_TRAV
  def initialize(load_from_file = false, session_file = "")
    info_register("Path_Traversal_Checker", {"group_name" => "default",
                              "group_priority" => 10,
                              "detail" => "Check whether content of a file can be read by injecting its file path to requests.",
                              "priority" => 10})
    if(load_from_file)
      begin
        @session_data = File.open(session_file, 'r').read
      rescue => exp
        @session_data = ""
        Log.warn(exp.to_s)
        Log.debug("#{exp.backtrace}")
      end
    end
  end

  def run
    vul_url = Array.new()
    #Filter the URLs that have a parameter which is a file
    Log.info( "Filtering URLs with file parameters...")

    tcks, params = filter_url_request

    if tcks != {}
      #Perform path traversal against the URLs filtered above
      vul_url = path_trav(tcks, params)
    end

    if vul_url == "error"
      error
    elsif vul_url != []
      vul_url.each do |v|
        m = v[0]
        v = v[1].gsub(/\\/, "")
        list(v, 'mthd' => m)
      end
      warn
    else
      abstain
    end
    Log.info("Path traversal check completed")
  end
end
