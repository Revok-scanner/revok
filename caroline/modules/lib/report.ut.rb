module ReportUtils

  def self.included(base)
    #blank
  end

  def register_if_needed
    return if @seen_before

    @seen_before = false
    @module_name = ''
    @lists = Hash.new

    @module_name = File.basename(caller[1]).gsub(/\.rb:.*/,'')
    report.modules.push(@module_name)
    report.modules =  report.modules.uniq {|x| x}
    @seen_before = true
  end
 
  def report
    $datastore.fetch('advice_report') do
      $datastore['advice_report'] = (Struct.new(:modules, :advice, :warnings, :lists, :errors)).new
      $datastore['advice_report'].modules = Array.new
      $datastore['advice_report'].advice = Array.new
      $datastore['advice_report'].warnings = Array.new
      $datastore['advice_report'].lists = Array.new
      $datastore['advice_report'].errors = Array.new
      $datastore['advice_report']
    end
  end

  def add_module(details)
    details['module_name'] = @module_name
  end

  def create_or_fetch_list
    @lists.fetch(@module_name) do
      @lists[@module_name] = Array.new
      report.lists.push({'module_name' => @module_name, 'list' => @lists[@module_name]})
      @lists[@module_name]
    end
  end

  def advise(details = {})
    register_if_needed
    add_module(details)
    details['list'] = create_or_fetch_list
    report.advice.push(details)
  end

  def warn(details = {})
    register_if_needed
    add_module(details)
    details['list'] = create_or_fetch_list
    report.warnings.push(details)
  end
    
  def list(url, details = {})
    register_if_needed
    items = create_or_fetch_list
    details['url'] = url
    items.push(details)
  end

  def abstain
    register_if_needed
  end

  def error
    register_if_needed
    report.errors.push(@module_name)
  end
end