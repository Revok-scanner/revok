require 'erb'
require 'json'
require 'core/module'
require "#{Revok::Config::MODULES_DIR}/report/adapter.rb"

class Renderer < Revok::Module

  def initialize
    info_register("Renderer", {"group_name" => "reportor",
                              "group_priority" => 99,
                              "priority" => 1,
                              "required" => true})
  end

  def run
    config = @datastore['config']
    @advice_report = @datastore['advice_report']
    return if not @advice_report || 
                  @advice_report.class == String

    config = JSON.parse(config, {create_additions:false})

    Log.info "Rendering executive report..."

    report = @advice_report
    Log.debug("Report class name: #{report.class.name}")
    Log.debug("Report: #{report}")
        
    class << report
      attr_accessor :config, :datastore
    end
    report.config = config
    report.datastore = @datastore

    Dir.chdir("#{Config::MODULES_DIR}/report/template") do
      Dir.glob("**/") do |subdir|
        Log.info "#{subdir}..."
        Dir.chdir(subdir) do
          to_fill = (report.send File.basename(subdir).to_sym).select {|mod| File.exist?(mod['module_name'] + '.erb')}
          to_fill.each do |hash|
            Log.info hash['module_name']
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

    Log.info "Rendering final report..."

    # Remove lists without list items
    @datastore['advice_report'].lists.delete_if{|x| x["list"] == []}

    executive_template = nil
    File.open("#{Config::MODULES_DIR}/report/template/report.erb",'r') {|f| executive_template = f.read}
    renderer = ERB.new(executive_template, 0, '>', "@output")
    rendered = renderer.result((Report_Adapter.new(report)).get_binding)

    @datastore['advice_report'] = rendered

    executive_template = nil
    File.open("#{Config::MODULES_DIR}/report/template/advice_email_body.erb",'r') {|f| executive_template = f.read}
    renderer = ERB.new(executive_template, 0, '>', "@output")
    rendered = renderer.result((Report_Adapter.new(report)).get_binding)

    @datastore['advice_email_body'] = rendered

    Log.info "Report is rendered"
    begin
      path = "#{Revok::ROOT_PATH}/report/"
      Dir.mkdir(path) if (!Dir.exist?(path))
      File.open("#{path}/#{@datastore['timestamp']}_report.html",'w') {|f| f.write @datastore['advice_report'] }
    rescue => exp
      Log.error(exp.to_s)
      Log.debug(exp.backtrace.join("\n"))
    end
  end

end
