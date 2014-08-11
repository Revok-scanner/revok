require 'erb'
require 'json'

class Detail_Adapter
  
  def initialize(dtls)
    @details = dtls
  end

  def priority(rnk)
    @details['priority'] = rnk
  end

  def name(nm)
    @details['name'] = nm
  end

  def url
     @details['url']
  end

  def details 
    @details
  end

  def get_binding
    binding
  end

  def shortlist(ref)
    if @details['list'].size > 0 and @details['list'].size <= 5
      yield
    else
      @output << ref 
      @output << "\n"
    end
  end

end

class Report_Adapter
  
  def initialize(rpt)
    @report = rpt
  end

  def get_binding
    binding
  end

  def report
    @report
  end
 
end

class Renderer

def initialize(config=$datastore['config'],advice_report=$datastore['advice_report'])
    @config=config
    @advice_report=advice_report
  end

  def run
    return if not @advice_report || 
                  @advice_report.class == String

    config = JSON.parse(@config, {create_additions:false})

    log "Rendering executive report..."

    report = @advice_report
        
    class << report
      attr_accessor :config, :datastore
    end
    report.config = config
    report.datastore=$datastore

    Dir.chdir("#{File.dirname(__FILE__)}/template") do
      Dir.glob("**/") do |subdir|
        log "Rendering #{subdir}..."
        Dir.chdir(subdir) do
          to_fill = (report.send File.basename(subdir).to_sym).select {|mod| File.exist?(mod['module_name'] + '.erb')}
          to_fill.each do |hash|
            log hash['module_name']
            File.open(hash['module_name'] + '.erb','r') do |file|
              template = file.read
              renderer = ERB.new(template, 0, '>', "@output")
              rendered = renderer.result((Detail_Adapter.new(hash)).get_binding)
              hash['rendered'] = rendered
            end
          end
        end
      end
    end

    log "Rendering final report..."

    # Remove lists without list items
    $datastore['advice_report'].lists.delete_if{|x| x["list"] == []}

    executive_template = nil
    File.open("#{File.dirname(__FILE__)}/template/report.erb",'r') {|f| executive_template = f.read}
    renderer = ERB.new(executive_template, 0, '>', "@output")
    rendered = renderer.result((Report_Adapter.new(report)).get_binding)

    $datastore['advice_report'] = rendered

    executive_template = nil
    File.open("#{File.dirname(__FILE__)}/template/advice_email_body.erb",'r') {|f| executive_template = f.read}
    renderer = ERB.new(executive_template, 0, '>', "@output")
    rendered = renderer.result((Report_Adapter.new(report)).get_binding)

    $datastore['advice_email_body'] = rendered

    log "Report rendered..."
    File.open("#{File.dirname(__FILE__)}/report.html",'w') {|f| f.write $datastore['advice_report']  }
    system("if test -f  #{File.dirname(__FILE__)}/report.html ;then echo -e \" [*] Create report Successfully.\"; else echo -e \" [*] Create  report failed.\"; fi")
    log "RESULT: PASS"
  end

end
