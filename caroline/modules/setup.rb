require 'json'
require 'core/module'

class Setup < Revok::Module

  def initialize
    info_register("Setup", {"group_name" => "system",
                              "group_priority" => 0,
                              "priority" => 3,
                              "required" => true})
  end

  def run
      #setup other options from @datastore['config'] and @datastore['session']
      config = JSON.parse(@datastore['config'], {create_additions:false})
      session = JSON.parse(@datastore['session'], {create_additions:false})
      @datastore['target'] = config['target']
      if (config['target'].index("https").nil?) then
        @datastore['port'] = 80
        @datastore['ssl'] = false
      else
        @datastore['port'] = 443
        @datastore['ssl'] = true
      end
      domain = config['target'].match(/(http(s)*:\/\/)*([^\/]+)(\/.*)*/)[3]
      if domain.scan(/:\d+/) != []
        @datastore['port'] = domain.split(':')[1]
        domain = domain.split(':')[0]
      end
      @datastore['host'] = domain
      @datastore['cookie'] = session['cookie']
      Log.info("Environment for running test modules are prepared")
  end

end
