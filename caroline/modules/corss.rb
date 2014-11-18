#
# Cross-Origin Resource Sharing Module
# Check whether URLs allow access from other or all origins by sending crafted HTTP requests.
#

$: << "#{File.dirname(__FILE__)}/lib/"
require 'report.ut'
require 'webrick'
require 'stringio'
require 'json'
require 'corss.rb.ut'

class CorssChecker
  include CORS
  include ReportUtils
  def initialize(config=$datastore['config'],session_data=$datastore['session'],flag='s')
    @config=config
    if flag=='f'
      @session_data=File.open(session_data).read
    else
      @session_data=session_data
    end
  end

  def run
    data = JSON.parse(@session_data, {create_additions:false})
    config = JSON.parse(@config, {create_additions:false})

    target = config['target']

    #delete duplicated requests
    uniq_tcks = del_dulp_reqs(data)
    #generate CORS requests
    req_hash = gen_cors_reqs(uniq_tcks, target, config, data)
    #send CORS requests and check the result headers
    log "Sending CORS requests and checking the result headers..."
    allow_oth, allow_all = send_cors_reqs(req_hash, data)
    
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
    log "corss is done"

  end
end

