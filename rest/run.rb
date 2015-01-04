module Revok
module Rest

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

  #def to_dict
  #  runDict={}
  #  runDict['id'] = @id if @id
  #  runDict['process'] = @process if @process
  #  runDict['targetInfo'] = @targetInfo if @targetInfo
  #  runDict['startTime'] = @startTime if @startTime
  #  runDict['endTime'] = @endTime if @endTime
  #  runDict['requestor'] = @requestor if @requestor
  #  runDict['type'] = @type if @type
  #  runDict['modules'] = @modules if @modules
  #  return runDict
  #end

  #attr_accessor   :id, :process, :targetInfo, :startTime, :endTime, :requestor, :type, :modules

end

end
end
