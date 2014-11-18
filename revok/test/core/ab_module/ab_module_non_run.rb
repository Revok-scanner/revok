require 'core/module'

class TestModule_NonRun < Revok::Module
	def initialize
		info_register("TestModule_NonRun", {"group_name" => "default",
											"group_priority" => 10,
											"priority" => 10})
	end
end
