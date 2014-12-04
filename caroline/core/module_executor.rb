require 'base64'
require 'json'
require_relative 'module'
require_relative 'modules'

module Revok

	class ModuleExecutor
		def initialize(run_case, modules = {})
			@modules = modules
			@exec_list = Array.new
			@datastore = Hash.new
			@datastore['run_id'] = run_case.id
			@datastore['process'] = run_case.process
			@datastore['config'] = run_case.targetInfo
			@datastore['scan_config'] = run_case.scanConfig
			@datastore['log'] = run_case.log
			@datastore['start'] = run_case.startTime
			@datastore['end'] = run_case.endTime
			@log_file = nil
		end

		def gen_exec_list_all
			@exec_list.clear
			if (self.modules.empty?)
				raise RuntimeError, "No any instance of modules", caller
			end
			self.modules.each {|_module|
				instance = _module[1]
				module_info = [instance.name,
								instance.info["group_name"],
								instance.info["group_priority"],
								instance.info["priority"]]
				@exec_list.push(module_info) if (instance.name != "Photographer")
			}
			@exec_list.sort_by! {|name, g_name, g_priority, priority|
				[g_priority, priority]
			}
		end

		def gen_exec_list(modules)
			@exec_list.clear
			if (self.modules.empty?)
				raise RuntimeError, "No any instance of modules", caller
			end
			if (modules.include?("Photographer"))
				instance = self.modules["Photographer"]
				module_info = [instance.name,
								instance.info["group_name"],
								instance.info["group_priority"],
								instance.info["priority"]]
				@exec_list.push(module_info)
				return
			end

			self.modules.each {|_module|
				instance = _module[1]
				module_info = [instance.name,
								instance.info["group_name"],
								instance.info["group_priority"],
								instance.info["priority"]]
				if (modules.include?(module_info[0]))
					@exec_list.push(module_info)
				end
				if (module_info[1] == "system")
					@exec_list.push(module_info)
				end
				if (module_info[1] == "reportor")
					@exec_list.push(module_info)
				end
			}
			@exec_list.sort_by! {|name, g_name, g_priority, priority|
				[g_priority, priority]
			}
		end

		def execute
			@datastore['timestamp'] = Time.now.strftime('%Y%m%d%H%M%S')
			if (self.exec_list.empty?)
				Log.warn("Run ID #{@datastore['run_id']}: the execute list is empty, nothing to do")
				return false
			end
			screenshot = self.exec_list.select {|name, g_name, g_priority, priority| name == "Photographer"}
			add_user_logger() if (screenshot.empty?)
			begin
				config_json = Base64.decode64(@datastore['config'])
				config = JSON.parse(config_json,{create_additions:false})
				@datastore['config']=JSON.dump(config)
				@datastore['start'] = `date`.slice(0..-2)
			rescue => exp
				Log.error("Run ID #{@datastore['run_id']}: invalid config")
				Log.debug(exp.backtrace.join("\n"))
				return false
			end
			Log.info("Running scan #{@datastore['run_id']}...")
			Log.info("Try to execute modules")
			self.exec_list.each {|name, g_name, g_priority, priority|
				Log.info("Run #{name} (priority: #{priority}, group name: #{g_name}, group priority: #{g_priority})")
				modules[name].datastore = @datastore
				begin
					modules[name].run
				rescue => exp
					Log.error("Module #{name} executed error")
					Log.debug(exp.backtrace.join("\n"))
				end
			}
			close_user_logger()
			return true
		end

		attr_reader		:exec_list
		attr_accessor	:modules, :datastore

		private

			def add_user_logger
				path = File.expand_path("report", Revok::ROOT_PATH)
				begin
					Dir.mkdir(path) if (!Dir.exist?(path))
					filename = File.expand_path("#{@datastore['timestamp']}_log.txt", path)
					@log_file = File.open(filename, File::WRONLY | File::APPEND | File::CREAT)
					@datastore['log_path'] = path
					logger = Logger.new(@log_file)
					Log.add_logger(logger)
				rescue => exp
					Log.error(exp.to_s)
					Log.debug(exp.backtrace.join("\n"))
				end
			end

			def close_user_logger
				begin
					Log.close_user_logger
					@log_file.close if (@log_file)
				rescue IOError
					#ignore any IO error
				end
			end

			attr_writer		:exec_list
	end

end
