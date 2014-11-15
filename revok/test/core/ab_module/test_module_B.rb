require 'core/module'

class TestModule_B < Revok::Module
	def initialize
		info_register("TestModule_B")
	end

	def run
		puts "#{self.class.name} run method implemented"
	end
end
