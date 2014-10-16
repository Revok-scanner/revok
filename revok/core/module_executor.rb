module Revok

	class ModuleExecutor
		def initialize
			self.modules = MODULES
			self.exec_list = Array.new
		end

		def gen_exec_list_all
			self.exec_list.clear
			modules_list = Array.new
			self.modules.each {|instance|
				module_info = [instance.name,
								instance.info["group_name"],
								instance.info["group_priority"],
								instance.info["priority"]]
				self.exec_list.push(module_info)
			}
			self.exec_list.sort_by! {|name, g_name, g_priority, priority|
				[g_priority, priority]
			}
		end

		def execute
			return if (self.exec_list.empty?)
			self.exec_list.each {|name, g_name, g_priority, priority|
				self.modules[name].run
			}
		end

		attr_reader		:exec_list

		private

			attr_accessor	:modules
			attr_writer		:exec_list
	end

end
