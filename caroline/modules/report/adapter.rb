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
