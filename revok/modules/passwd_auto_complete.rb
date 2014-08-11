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
      return true
    elsif node.name == "form" || node.name == "html"
      return false
    else
      return find_auto_complete(node.parent)
    end
  end

  def run
    log "Check auto-complete enabled on pass parameters" 
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
          issues.push("Invalid login page.")
          result = true
        end
      else
        log "Login-type is not form-based" 
        result = true
      end
    rescue => exp 
      log exp.to_s 
      issues.push(exp)
      result = false
    end

    if result
      abstain
      log "RESULT: PASS" 
    else
      if issues.size != 0
        issues.each do |issue|
          log "\tIssue: #{issue}\n" 
        end
        error
        log "RESULT: ERROR" 
        return
      end
      advise({'login_page'=>target})
      log "RESULT: FAIL" 
    end

  end
end
