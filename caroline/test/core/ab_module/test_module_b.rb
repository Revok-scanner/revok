require 'core/module'

class TestModule_b < Revok::Module
	def initialize
		info_register("TestModule_b", {"group_name" => "test_group",
											"group_priority" => 11,
											"priority" => 12})
	end

	def run
		puts "#{self.class.name} run method implemented"
	end
end
