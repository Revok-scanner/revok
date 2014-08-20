$: << "#{File.dirname(__FILE__)}/modules/lib/"
$: << "#{File.dirname(__FILE__)}/modules/"
$: << "#{File.dirname(__FILE__)}/modules/crawler/"
$: << "#{File.dirname(__FILE__)}/modules/report/"

require 'sqli'
require 'render'
require 'email_intro'
require 'email_report'
require 'ssl_check'
require 'redir'
require 'bruteforce'
require 'anti_reflection'
require 'passwd_auto_complete'
require 'frame_busting'
require 'mime_type_check'
require 'method_check'
require 'cookie_attr_check'
require 'reverse_cookie'
require 'path_traversal'
require 'autologin'
require 'json'
require 'base64'
require 'crawler_new'
require 'snks'
require 'utils'
require 'sitemap'
require 'xssi'
require 'corss'
require 'access_admin'
require 'session_exposed_in_url'
require 'session_fixation'
require 'screenshot'
require 'send_notify'

module Revok
  include Utils

  def run_case(runCase)
    $datastore={}
    $datastore['RUN_ID']=runCase.id
    $datastore['process']=runCase.process
    $datastore['config']=runCase.targetInfo
    $datastore['scan_config']=runCase.scanConfig
    $datastore['log']=runCase.log
    $datastore['start'] = runCase.startTime
    $datastore['end'] = runCase.endTime
    use_smtp = ENV['USE_SMTP'].downcase

    #prepared
    begin
      config_json=Base64.decode64($datastore['config'])
      config_dict=JSON.parse(config_json,{create_additions:false})
      email_flag=1 if  config_dict['email'] !=nil and config_dict['email']!=""
      $datastore['config']=JSON.dump(config_dict)
      $datastore['start'] = `date`.slice(0..-2)
    rescue => exp
      log $!
      log "#{exp.backtrace.join("\n")}"
      return -1
    end
    #end of prepared

    pretreated(runCase.scanConfigObj.screenshot,'screenshot'){
      photographer=Photographer.new
      photographer.shot
    }

    if use_smtp == "off"
      pretreated(runCase.scanConfigObj.sendnotify, 'send a pop-up notification') {
        notify = NotifySender.new
        notify.send_msg("Revok", "Your scan has begun. Depending on server load, you should receive a second notification when the scan finish.")
      }
    else
      pretreated(runCase.scanConfigObj.sendemail,'send introduction email'){
        p1=Postman1.new
        p1.send
      }
    end

    #this module will set global datastore['config']
    pretreated(runCase.scanConfigObj.autologin,'autologin'){
      auto=Autologin.new
      auto.run
    }

    #prepare the paremeters for crawler
    pretreated(runCase.scanConfigObj.crawler,'crawler'){
      config=JSON.parse($datastore['config'],{create_additions:false})
      config['initial_delay'] = 15000
      config = JSON.dump(config)
      width = 1280
      height = 800
      attempts = 25
      delay = 2000
      depth = 8
      time = 180
      $datastore['config']=config

      #crawler will set global $datastore['injections'] and $datastore['walk']
      crawler=Crawler.new(config,width,height,attempts,delay,depth,time)
      crawler.run
    }

    #null sesion module in case of nil result
    pretreated(runCase.scanConfigObj.crawler,'null session'){
      if $datastore['injections'] == "" || $datastore['walk'] == ""
        log "The crawler may doesn't run correctly, the null session module launched."
        array=Utils.fake_session
        $datastore['injections']=array[0]
        $datastore['walk']=array[1]
      end
    }

    pretreated(runCase.scanConfigObj.crawler,'merge and snk'){
      #merge stage 1
      comp=Utils.merge($datastore['injections'],$datastore['walk'])
      #get snk option
      snker=Snks.new(comp,'s')
      snk=snker.run
      #merge stage 2(get $datastore['session'])
      $datastore['session']=Utils.merge(comp,snk)
    }
    pretreated(runCase.scanConfigObj.crawler,'setup'){
      #setup other options from $datastore['config'] and $datastore['session']
      config = JSON.parse($datastore['config'], {create_additions:false})
      session = JSON.parse($datastore['session'], {create_additions:false})
      $datastore['target']=config['target']
      if (config['target'].index("https").nil?) then
        $datastore['port'] = 80
        $datastore['ssl'] = false
      else
        $datastore['port'] = 443
        $datastore['ssl'] = true
      end
      domain = config['target'].match(/(http(s)*:\/\/)*([^\/]+)(\/.*)*/)[3]
      if domain.scan(/:\d+/) != []
        $datastore['port'] = domain.split(':')[1]
        domain = domain.split(':')[0]
      end
      $datastore['host'] = domain
      $datastore['cookie'] = session['cookie']
    }

    #sitemap, return the list of map
    pretreated(runCase.scanConfigObj.sitemap,'sitemap'){
      maper=Sitemaper.new
      maper.run
    }

    #corss module
    pretreated(runCase.scanConfigObj.corss,'corss'){
      cs=CorssChecker.new
      cs.run
    }

    #access_admin module
    pretreated(runCase.scanConfigObj.access_admin,'access_admin'){
      s=AdminAccessor.new
      s.run
    }

    #path_traversal module
    pretreated(runCase.scanConfigObj.path_traversal,'path_traversal'){
      pt=PathTravelor.new
      pt.run
    }

    #session_exposed_in_url module
    pretreated(runCase.scanConfigObj.session_check,'session_exposed_in_url'){
      sc=SessionExposureCheckor.new
      log "detecting session_id"
      sc.session_id_detect
      log "checking session_id exposure in url"
      sc.exposure_check
    }

    #session_fixation module
    pretreated(runCase.scanConfigObj.session_check,'session_fixation'){
      sc=SessionFixationCheckor.new
      sc.fixation_check
    }

    #cookie_attr_check module
    pretreated(runCase.scanConfigObj.cookie_check,'cookie_attr_check'){
      cc=CookieAttrChecker.new
      log "checking cookie attr"
      cc.run
    }

    #reverse_cookie module
    pretreated(runCase.scanConfigObj.cookie_check,'reverse_cookie'){
      log "reversing cookie"
      rc=CookieReverser.new
      rc.run
    }

    #mime_type module
    pretreated(runCase.scanConfigObj.mime_type,"mime_type"){
      mc=MimeTypeChecker.new
      mc.run
    }

    #frame_busting module
    pretreated(runCase.scanConfigObj.frame_busting,'frame_busting'){
      fb=FrameBustingTester.new
      fb.run
    }

    #method_check module
    pretreated(runCase.scanConfigObj.method_check,'method_check'){
      mc=MethodCheckor.new
      mc.run
    }

    #passwd_auto_complete module
    pretreated(runCase.scanConfigObj.autocomplete,'passwd_auto_complete'){
      pa=PasswordAutoCompleteChecker.new
      pa.run
    }

    #bruteforce module
    pretreated(runCase.scanConfigObj.bruteforce,'bruteforce'){
      bf=BruteForceCheckor.new
      bf.run
    }

    #anti_reflection module
    pretreated(runCase.scanConfigObj.anti_reflection,'anti_reflection'){
      ar=AntiReflectionChecker.new
      ar.run
    }

    #redir module
    pretreated(runCase.scanConfigObj.redir_check,"redir check"){
      rd=RedirChecker.new
      rd.run
    }

    #ssl_check module
    pretreated(runCase.scanConfigObj.ssl_check,"ssl_check"){
      s=SSLChecker.new
      s.run
    }

    #sqli module
    pretreated(runCase.scanConfigObj.sqli_check,'sqli'){
      sq=SQLiChecker.new
      sq.run
    }

    #xssi module
    pretreated(runCase.scanConfigObj.xssi_check,'xssi'){
      xss=XSSChecker.new
      xss.run
    }

    pretreated(runCase.scanConfigObj.render,'render report'){
      renderer=Renderer.new
      renderer.run
    }

    if use_smtp == "off"
      pretreated(runCase.scanConfigObj.sendnotify, 'send a pop-up notification') {
        system("ln -s #{File.dirname(__FILE__)}/modules/report/report.html #{File.dirname(__FILE__)}/../report/report.html")
        notify = NotifySender.new
        notify.send_msg("Revok", "Your scan has finished, access {revok_directory}/report to review it")
      }
    else
      pretreated(runCase.scanConfigObj.sendemail,'send report email'){
        p2=Postman2.new
        p2.send
      }
    end

    #update runcase
    runCase.setProcess("==========")
    runCase.setLog($datastore['log'])
    runCase.setEndTime(Time.now.to_i)

  end
end
