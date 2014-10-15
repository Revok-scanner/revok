
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

		protected
			def info_register(name, info = {}) 
				self.name = name
				self.info = info
			end

			attr_writer		:name
			attr_writer		:info

  end
end
