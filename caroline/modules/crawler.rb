require 'io/wait'
require 'open3'
require 'json'
require 'socket'
require 'core/module'

class Crawler < Revok::Module

  def cleanProcs
    mitmdump = `ps -ef | grep mitmdump | grep -v grep | awk '{print $2}'`.to_i
    Process.kill 'KILL', mitmdump if mitmdump > 0
    phantom = `ps -ef | grep phantomjs | grep -v grep | awk '{print $2}'`.to_i
    Process.kill 'KILL', phantom if phantom > 0
  end

  def initialize
    info_register("Crawler", {"group_name" => "system",
                                "group_priority" => 0,
                                "priority" => 1,
                                "detail" => "",
                                "required" => true})

    @width = 1280
    @height = 800
    @attempts = 25
    @delay = 2000
    @depth = 8
    @time = 180
  end

  def run
    config = @datastore['config']
    config = JSON.parse(config, {create_additions:false})
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
    config['duration'] = @time * 1000 + 60 * 1000
    config['depth'] = @depth
    config = JSON.dump(config)

    cleanProcs
    sleep 5

    mitm_in, mitm_out, mitm_err, mitm_thd = Open3.popen3("mitmdump -s #{Revok::Config::MODULES_DIR}/creep/creep.py #{ip} -q")
    mitmid = `ps -ef | grep mitmdump | grep -v grep | awk '{print $2}'`.to_i
    Log.debug("Mitmdump PID: #{mitmid}")
    if mitmid > 0
      Log.info("mitmdump is started")
    else
      return
    end
    mitm_in.close
    sleep 5

    crawl_in, crawl_out, crawl_err = Open3.popen3("cd #{Revok::Config::MODULES_DIR};phantomjs --proxy=localhost:8080 --ignore-ssl-errors=true --ssl-protocol=any #{Revok::Config::MODULES_DIR}/creep/webcrawler.js")
    phantomjsid = `ps -ef | grep phantomjs | grep -v grep | grep -v sh |awk '{print $2}'`.to_i
    Log.debug("Phantomjs PID: #{phantomjsid}")
    if phantomjsid > 0
      Log.info("phantomjs is started")
    else
      return
    end
    crawl_in.puts config
    crawl_in.close
    Log.info("Crawling the application #{target}...")

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
      Log.info("Asking mitmdump to stop...") if mitmdump > 0
      Process.kill 'INT', mitmdump if mitmdump > 0
    rescue
      Log.warn("mitmdump is probably still running")
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

    injections = injections.join('')
    walk = walk.join('')
    if walk != "" and injections == ""
     injections = "{\"tags\":{}, \"ticks\":[{\"url\":\"#{target}\"}]}"
    end
    @datastore['injections'] = injections
    @datastore['walk'] = walk

    sleep 10
    cleanProcs

    if injections.nil? or injections.size < 1 or walk.nil? or walk.size < 1
      Log.warn("No crawling result")
    end

    Log.info("Crawler completed")

  end

end
