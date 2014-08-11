require 'io/wait'
require 'open3'
require 'json'
require 'socket'


class Crawler

  def cleanProcs
    mitmdump = `ps -ef | grep mitmdump | grep -v grep | awk '{print $2}'`.to_i
    Process.kill 'KILL', mitmdump if mitmdump > 0
    phantom = `ps -ef | grep phantomjs | grep -v grep | awk '{print $2}'`.to_i
    Process.kill 'KILL', phantom if phantom > 0
  end

  def initialize(config,width=1280,height=800,attempts=25,delay=2000,depth=8,time=180)
    @config=config
    @width=width
    @height=height
    @attempts=attempts
    @delay=delay
    @depth=depth
    @time=time
  end

  def run
    config = JSON.parse(@config, {create_additions:false})
    begin
      ip = config['target'].split('/')[2]
      target = config['target']
    rescue
      ip = '123.123.123.123'#Is there any target with no "/"?
    end
    config['width'] = @width
    config['height'] = @height
    config['attempts'] = @attempts
    config['delay'] = @delay
    config['duration'] = @time*1000 + 60*1000
    config['depth'] = @depth
    config = JSON.dump(config)

    cleanProcs
    sleep 10
    mitm_in, mitm_out, mitm_err, mitm_thd = Open3.popen3("mitmdump -s #{File.dirname(__FILE__)}/creep/creep.py #{ip} -q")
    mitmid = `ps -ef | grep mitmdump | grep -v grep | awk '{print $2}'`.to_i
    if mitmid>0
      log 'mitmdump'
    else
      log "RESULT: FAIL"
      return
    end
    mitm_in.close
    sleep 5

    crawl_in, crawl_out, crawl_err = Open3.popen3("cd #{File.dirname(__FILE__)};phantomjs --proxy=localhost:8080 --ignore-ssl-errors=true #{File.dirname(__FILE__)}/creep/webcrawler.js")
    phantomjsid = `ps -ef | grep phantomjs | grep -v grep | grep -v sh |awk '{print $2}'`.to_i
    if phantomjsid>0
      log 'phantomjs'
    else
      log "RESULT: FAIL"
      return
    end
    crawl_in.puts config
    crawl_in.close

    buffer = Array.new
    start = Time.now.to_i

    injections = Array.new
    walk = Array.new

    while Time.now.to_i - start < @time do
      sleep 5
    end

    report_idle = 0
    bytes = 0
    report = Thread.new {
      while true
        if !mitm_err.ready? and !mitm_out.ready? and !crawl_out.ready? and !crawl_err.ready? then
          if bytes > 100
            report_idle = report_idle + 1
          end
          sleep 1
        else
          report_idle = 0
        end
        walk.push(mitm_out.read_nonblock(1024)) if mitm_out.ready?
        if crawl_out.ready?
          buffer = crawl_out.read_nonblock(1024)
          bytes = bytes + buffer.size
          injections.push(buffer)
        end
        mitm_err.read_nonblock(1024) if mitm_err.ready?
        crawl_err.read_nonblock(1024) if crawl_err.ready?
      end
    }

    sleep 10

    begin
      mitmdump = `ps -ef | grep mitmdump | grep -v grep | awk '{print $2}'`.to_i
      log "asking mitmdump to stop" if mitmdump > 0
      log "#{mitmdump}" if mitmdump > 0
      Process.kill 'INT', mitmdump if mitmdump > 0
    rescue
      log "mitmdump was probably already running"
    end

    while report_idle < 30
       sleep 10
      if Time.now.to_i - start > @time+150
        break;
      end
    end

    report.exit

    injections.push(crawl_out.read) if crawl_out.ready?
    walk.push(mitm_out.read) if mitm_out.ready?

    crawl_out.close
    crawl_err.close
    mitm_out.close
    mitm_err.close
    log "pipes closed"

    injections = injections.join('')
    walk = walk.join('')
    if walk != "" and injections == ""
     injections = "{\"tags\":{}, \"ticks\":[{\"url\":\"#{target}\"}]}"
    end
    $datastore['injections']=injections
    $datastore['walk']=walk


    sleep 10
    cleanProcs

    log walk.size
    log injections.size
    #p injections

    if injections.nil? or injections.size < 1 or walk.nil? or walk.size < 1
      log "RESULT: FAIL"
    else
      log "RESULT: PASS"
    end

  end

end
