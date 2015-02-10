module Revok

class Run < Hash
  def initialize(data = {})
    super
    set_data(data)
  end

  def set_data(data)
    if data.class == Hash
      self['id'] = data['id']
      self['process'] = data['process']
      self['target_info'] = data['target_info']
      self['start_time'] = data['start_time']
      self['end_time'] = data['end_time']
      self['requestor'] = data['requestor']
      self['type'] = data['type']
      self['modules'] = data['modules']
    end
  end

end

end
