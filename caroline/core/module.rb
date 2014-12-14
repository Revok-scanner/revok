module Revok

	class Module
		def initialize
			raise NotImplementedError
		end

		def run
			raise NotImplementedError
		end

		def clean
			@seen_before = false
			@datastore = nil
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
				info["detail"] = "" if (!info.has_key?("detail"))
				info["required"] = false if (!info.has_key?("required"))
				info["required"] = false if (info["required"].class.name != "TrueClass" && info["required"].class.name != "FalseClass")

				self.name = name
				self.info = info
			end

			def self.included(base)
				#blank
			end

			def register_if_needed
				return if @seen_before

				@seen_before = false
				@filename = self.class::FILE_NAME
				@lists = Hash.new

				report.modules.push(@filename)
				report.modules = report.modules.uniq {|x| x}
				@seen_before = true
			end

			def report
				@datastore.fetch('advice_report') do
					@datastore['advice_report'] = (Struct.new(:modules, :advice, :warnings, :lists, :errors)).new
					@datastore['advice_report'].modules = Array.new
					@datastore['advice_report'].advice = Array.new
					@datastore['advice_report'].warnings = Array.new
					@datastore['advice_report'].lists = Array.new
					@datastore['advice_report'].errors = Array.new
					@datastore['advice_report']
				end
			end

			def add_module(details)
				details['module_name'] = @filename
			end

			def create_or_fetch_list
				@lists.fetch(@filename) do
					@lists[@filename] = Array.new
					report.lists.push({'module_name' => @filename, 'list' => @lists[@filename]})
					@lists[@filename]
				end
			end

			def advise(details = {})
				register_if_needed
				add_module(details)
				details['list'] = create_or_fetch_list
				report.advice.push(details)
			end

			def warn(details = {})
				register_if_needed
				add_module(details)
				details['list'] = create_or_fetch_list
				report.warnings.push(details)
			end

			def list(url, details = {})
				register_if_needed
				items = create_or_fetch_list
				details['url'] = url
				items.push(details)
			end

			def abstain
				register_if_needed
			end

			def error
				register_if_needed
				report.errors.push(@filename)
			end

			attr_writer		:name
			attr_writer		:info

  end
end
