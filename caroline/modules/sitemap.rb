# Sitemap module
#    You can call the result of this module like this:
#
#    <ruby>
#        session = JSON.parse(datastore['SESSION'], {create_additions:false})
#        path_list = session['sitemap']
#    </ruby>
#
#    The var "path_list" is a array.
#

require 'json'
require 'net/http'
require 'core/module'
require "#{Revok::Config::MODULES_DIR}/lib/path_tree.rb"

class Sitemap < Revok::Module
  def initialize(load_from_file = false, session_file = "")
    info_register("Sitemap", {"group_name" => "system",
                              "group_priority" => 0,
                              "priority" => 4,
                              "required" => true})
    if(load_from_file)
      begin
        @session_data = File.open(session_file, 'r').read
      rescue => exp
        @session_data = ""
        Log.warn(exp.to_s)
        Log.debug("#{exp.backtrace}")
      end
    end
  end

  def run
    @session_data = @datastore['session'] if @session_data == nil
    target = @datastore['target']
    urls = Array.new()
    path_list = Array.new()
    issues = Array.new()
    result = true
    begin
      session = JSON.parse(@session_data, {create_additions:false})
      domain = URI(target).host
      requests = session['requests']
      Log.info("Generating the directory structure of this site...")

      #extracting url from each request
      requests.each_pair {|key, value|
        url = /\b(https?|ftp|file):\/\/\S+/.match(value)
        begin
          uri = URI(url.to_s)
        rescue
          uri = URI(target)
        end
        if(uri.path != nil && url.to_s.include?(domain))
          urls.push(uri.path)
        end
      }
      urls.uniq!

      #building the directory structure
      path_tree = PathTree.new
      urls.each {|url|
        path_tree.add_path(url)
      }
      Log.info("Directory structure:")
      path_tree.each {|path|
        url = URI(target).scheme + "://" + domain + path
        path_list << url
        Log.info(url)
      }
    end

    if result
      if !path_list.empty?
        path_list.each {|path|
          list(path)
        }
        session['sitemap'] = path_list
        @datastore['session'] = JSON.dump(session).to_s
      end
    else
      if issues.size > 0
        issues.each do |issue|
          Log.error("#{issue}")
        end
      end
      error
    end
    @session_data = nil
    Log.info("Site map generated")
  end
end

