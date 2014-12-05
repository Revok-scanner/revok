#
# Auto Complete Password Module
# Check whether password field turns off the autocomplete option.
#
require 'nokogiri'
require 'open-uri'
require 'json'
require 'openssl'
require 'core/module'

class PasswordAutoCompleteChecker < Revok::Module
  def initialize
    info_register("Auto_Complete_Password_Checker", {"group_name" => "default",
                                "group_priority" => 10,
                                "priority" => 10,
                                "detail" => "Check whether password field turns off the autocomplete option."})
  end
  
  def find_auto_complete(node)
    if node.to_s.include?("autocomplete=\"off\"")
      Log.warn("auto-complete is not enabled")
      return true
    elsif node.name == "form" || node.name == "html"
      return false
    else
      return find_auto_complete(node.parent)
    end
  end
  
  def run
    Log.info("Checking auto-complete attribute of password parameters...")
    result = false
    issues = []
    target = ""
    begin
      config = @datastore['config']
      config = JSON.parse(config, {create_additions:false})
      if config['logtype'] == "normal"
        target = config['login']
        Log.info("Access login page #{target}")
        doc = Nokogiri::HTML(open(target, :ssl_verify_mode => OpenSSL::SSL::VERIFY_NONE))
        passwd_element = doc.css("input[type='password']")

        if !passwd_element.empty?
          result = find_auto_complete(passwd_element[0])
        else
          Log.warn("Invalid login page.")
          result = true
        end
      else
        Log.info("Login-type is not form-based")
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
          Log.error("#{issue}\n")
        end
        error
        return
      end
      advise({'login_page'=>target})
      Log.warn("auto-complete is enabled")
    end
    Log.info("Auto complete password check completed")
  end
end
