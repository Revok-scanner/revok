require 'core/module'

class TestModule_Default < Revok::Module
	def initialize
		info_register("TestModule_Pass_Default")
	end

	def run
		puts "#{self.class.name} run method implemented"
	end
end
