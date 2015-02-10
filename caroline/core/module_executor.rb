require 'base64'
require 'json'
require_relative 'module'
require_relative 'modules'
require_relative 'postman'

module Revok

	class ModuleExecutor
		RUNNING = 1
		FINISHED = 2

		def initialize(run, modules = {})
			@modules = modules
			@exec_list = Array.new
			@datastore = Hash.new
			@datastore['run_id'] = run['id']
			@datastore['process'] = run['process']
			@datastore['config'] = run['target_info']
			@datastore['scan_config'] = run['scan_config']
			@datastore['start'] = run['start_time']
			@datastore['end'] = run['end_time']
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
			config = ""
			@datastore['timestamp'] = Time.now.strftime('%Y%m%d%H%M%S')
			if (self.exec_list.empty?)
				Log.warn("Run ID #{@datastore['run_id']}: the execute list is empty, nothing to do")
				return false
			end
			screenshot = self.exec_list.select {|name, g_name, g_priority, priority| name == "Photographer"}

			begin
				config_json = Base64.decode64(@datastore['config'])
				config = JSON.parse(config_json, {create_additions:false})
				@datastore['config']=JSON.dump(config)
				@datastore['start'] = `date`.slice(0..-2)
			rescue => exp
				Log.error("Run ID #{@datastore['run_id']}: invalid config")
				Log.debug(exp.backtrace.join("\n"))
				return false
			end

			if (screenshot.empty?)
				add_user_logger()
				if (Config::USE_SMTP == "off")
					send_notify("Revok", "Your scan has begun. Depending on server load, you should receive a second notification when the scan is finished in about an hour.")
					set_status(RUNNING)
				else
					begin
						Postman::send_intro(config['email'], config['target'])
					rescue => exp
						Log.warn("Send intro mail failed: #{exp.to_s}")
						Log.debug(exp.backtrace.join("\n"))
					end
				end
			end

			Log.info("Running scan #{@datastore['run_id']}...")
			Log.info("Try to execute modules")
			self.exec_list.each {|name, g_name, g_priority, priority|
				Log.info("Run #{name} (priority: #{priority}, group name: #{g_name}, group priority: #{g_priority})")
				modules[name].datastore = @datastore
				begin
					modules[name].run
					modules[name].clean
				rescue => exp
					Log.error("Module #{name} executed error: #{exp.to_s}")
					Log.debug(exp.backtrace.join("\n"))
				end
			}
			Log.info("Scan #{@datastore['run_id']} is finished")

			if (screenshot.empty?)
				close_user_logger()
				if (Config::USE_SMTP == "off")
					send_notify("Revok", "Your scan has finished, please access {revok_directory}/report to view the report.")
					set_status(FINISHED)
				else
					if @datastore["advice_report"] != nil
						failed = false
					else
						failed = true
					end
					begin
						Postman::send_report(config['email'], config['target'], @datastore["advice_email_body"], @datastore["timestamp"], failed)
					rescue => exp
						Log.warn("Send intro mail failed: #{exp.to_s}")
						Log.debug(exp.backtrace.join("\n"))
					end
				end
			end
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

			def send_notify(title = "", body = "")
				begin
					system("notify-send '#{title}' '#{body}' -t 0")
				rescue => exp
					Log.error(exp.to_s)
					Log.debug(exp.backtrace.join("\n"))
				end
			end

			def set_status(status)
				begin
					f = File.open("#{Revok::ROOT_PATH}/report/00-STATUS", 'w')
					if (status == RUNNING)
						f.write("Scan #{@datastore['run_id']}(#{@datastore['timestamp']}) is running...")
					elsif (status == FINISHED)
						f.write("Scan #{@datastore['run_id']}(#{@datastore['timestamp']}) is FINISHED.")
					end
					f.close
				rescue => exp
					Log.warn("Update status file error: #{exp.to_s}")
					Log.debug(exp.backtrace.join("\n"))
				end
			end

			attr_writer		:exec_list
	end

end
