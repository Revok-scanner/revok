#
# Auto Complete Password Module
# Check whether password field turns off the autocomplete option.
#

$: << "#{File.dirname(__FILE__)}/lib/"
require 'report.ut'
require 'nokogiri'
require 'open-uri'
require 'json'
require 'openssl'

class PasswordAutoCompleteChecker
  include ReportUtils
  def initialize(config=$datastore['config'])
    @config=config
  end

  def find_auto_complete(node)
    if node.to_s.include?("autocomplete=\"off\"")
      log "auto-complete is not enabled"
      return true
    elsif node.name == "form" || node.name == "html"
      return false
    else
      return find_auto_complete(node.parent)
    end
  end

  def run
    log "Checking auto-complete attribute of password parameters..." 
    result = false
    issues = []
    target = ""
    begin
      config = JSON.parse(@config, {create_additions:false})
      if config['logtype'] == "normal"
        target = config['login']
        log "Access login page #{target}" 
        doc = Nokogiri::HTML(open(target, :ssl_verify_mode => OpenSSL::SSL::VERIFY_NONE))
        passwd_element = doc.css("input[type='password']")

        if !passwd_element.empty?
          result = find_auto_complete(passwd_element[0])
        else
          log "Invalid login page." 
          result = true
        end
      else
        log "Login-type is not form-based" 
        result = true
      end
    rescue => exp 
      issues.push(exp)
    end

    if result
      abstain
    else
      if issues.size != 0
        issues.each do |issue|
          log "ERROR: #{issue}\n" 
        end
        error
        return
      end
      advise({'login_page'=>target})
      log "auto-complete is enabled"
    end

  end
end
