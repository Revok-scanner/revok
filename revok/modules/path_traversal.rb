#
# Path Traversal Checking Module
# Check whether content of a file can be read by injecting its file path to requests.
#
require 'json'
require 'core/module'
require "#{Revok::Config::MODULES_DIR}/lib/report.ut.rb"
require "#{Revok::Config::MODULES_DIR}/lib/path_traversal.rb.ut.rb"

class PathTravelor < Revok::Module
  include PATH_TRAV
  include ReportUtils
  def initialize(load_from_file = false, session_file = "")
    info_register("PathTravelor", {"group_name" => "default",
                              "group_priority" => 10,
                              "priority" => 10})
  end

  def run
    vul_url = Array.new()
    #Filter the URLs that have a parameter which is a file
    Log.info( "Filtering URLs with file parameters...")
    begin
    tcks, params = filter_url_request
    rescue => exp
       Log.error("#{exp}")
       return
    end
    if tcks != {}
      #Perform path traversal against the URLs filtered above
      vul_url = path_trav(tcks, params)
    end
    if vul_url == "error"
      Log.error("#{exp}")
    elsif vul_url != []
      vul_url.each do |v|
        m = v[0]
        v = v[1].gsub(/\\/, "")
        list(v, 'mthd' => m)
      end
     
    else
#      abstain
    end
  end
end
