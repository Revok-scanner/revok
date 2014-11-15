require 'core/module'

class TestModule < Revok::Module
	def initialize
		info_register("TestModule_Pass", {"group_name" => "test_group",
											"group_priority" => 11,
											"priority" => 11})
	end

	def run
		puts "#{self.class.name} run method implemented"
	end
end
