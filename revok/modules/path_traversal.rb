#
# Path Traversal Checking Module
# Check whether content of a file can be read by injecting its file path to requests.
#

$: << "#{File.dirname(__FILE__)}/lib/"
require 'report.ut'
require 'json'
require 'path_traversal.rb.ut'

class PathTravelor
  include PATH_TRAV
  include ReportUtils
  def initialize(config=$datastore['config'],session_data=$datastore['session'],flag='s')
    @config=config
    if flag=='f'
      begin
        @session_data=File.open(session_data,'r').read 
      rescue =>exp
        log exp.to_s 
        @session_data=""
      end
    elsif flag=="s"
      @session_data=session_data
    else
      log 'unknow flag' 
      return nil
    end
  end

  def run
    result = "PASS"
    vul_url = Array.new()

    #Filter the URLs that have a parameter which is a file
    tcks, params = filter_url_request

    if tcks != {}
      #Perform path traversal against the URLs filtered above
      vul_url = path_trav(tcks, params)
    end

    if vul_url == "error"
       result = "ERROR"
       error
    elsif vul_url != []
      vul_url.each do |v|
        m = v[0]
        v = v[1].gsub(/\\/, "")
        list(v, 'mthd' => m)
      end
      result = "FAIL"
      warn
    else
      abstain
    end

    log "RESULT: #{result}" 
  end
end
