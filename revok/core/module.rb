require_relative 'utils'

module Revok

	class Module
		def initialize
			raise NotImplementedError
		end

		def run
			raise NotImplementedError
		end

		attr_reader		:name
		attr_reader		:info
		attr_accessor		:datastore

		protected
			def info_register(name, info = {}) 
				if (name.class.name != "String")
					raise ArgumentError, "#{self.class.name}: Invalid module name type, it should be String", caller
				end
				if (info.class.name != "Hash")
					raise ArgumentError, "#{self.class.name}: Invalid module info type, it should be Hash", caller
				end

				info["group_name"] = "default" if (!info.has_key?("group_name"))
				info["group_priority"] = 10 if (!info.has_key?("group_priority"))
				info["group_priority"] = 10 if ((info["group_name"] == "default") && (info["group_priority"] != 10))
				info["priority"] = 10 if (!info.has_key?("priority"))

				self.name = name
				self.info = info
			end

			attr_writer		:name
			attr_writer		:info

  end
end
