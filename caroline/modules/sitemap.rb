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

$: << "#{File.dirname(__FILE__)}/lib"
require 'report.ut'
require 'json'
require 'net/http'
require 'path_tree'

class Sitemaper
  include ReportUtils
  def initialize(target=$datastore['target'],session_data=$datastore['session'],flag='s')
    @target=target
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
    urls = Array.new()
    path_list = Array.new()
    issues = Array.new()
    result = true
    begin
      session = JSON.parse(@session_data, {create_additions:false})
      target=@target
      domain = URI(target).host
      requests = session['requests']
      log "Generating the directory structure of this site..." 

      #extracting url from each request
      requests.each_pair {|key,value|
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
      log "Directory structure:" 
      path_tree.each {|path|
        url = URI(target).scheme + "://" + domain + path
        path_list << url
        log url 
      }
    # rescue => exp 
      # issues.push(exp.to_s)
      # p exp.to_s
      # result = false
    end

    if result
      if !path_list.empty?
        path_list.each {|path|
          list(path)
        }
        session['sitemap'] = path_list
        $datastore['session'] = JSON.dump(session).to_s
      end
    else
      if issues.size > 0
        issues.each do |issue|
          log "ERROR: #{issue}" 
        end
      end
      error
    end
   
  end
end

