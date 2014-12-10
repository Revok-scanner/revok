require_relative 'config'
require_relative 'module'
require_relative 'modules'

module Revok

	class Framework
		def initialize
			self.load_error_modules = Array.new
			self.modules_loaded = Array.new
			if (Dir.exist?(Revok::Config::MODULES_DIR))
				@modules_path = Revok::Config::MODULES_DIR
			end
			@modules = Hash.new
		end

		def load_modules
			path = self.modules_path.to_s + '/'
			begin
				if (Dir.exist?(path))
					Dir.foreach(path) {|filename|
						next if (filename[0] == '.')
						next if (File.extname(filename) != ".rb")
						begin
							load_module(path, filename)
						rescue IOError, NameError, SyntaxError => exp
							self.load_error_modules.push(path + filename)
							Log.debug(exp.to_s)
							Log.debug(exp.backtrace.join("\n"))
						end
					}
				else
					raise RuntimeError, "The directory of moudles is invalid", caller
				end

				if (!self.load_error_modules.empty?)
					Log.warn("Some modules are failed to load: #{self.load_error_modules.to_s}")
					return false
				end

				return true
			rescue RuntimeError => exp
				Log.error(exp.to_s)
				Log.debug(exp.backtrace.join("\n"))
			end
		end

		def load_module(path, filename)
			file = File.read(path + filename)
			Revok::Modules.module_eval file
			class_name = Revok::Modules.constants.last
			symbol = Revok::Modules.const_get(class_name)
			symbol.const_set("FILE_NAME", File.basename(filename, ".rb"))
			self.modules_loaded.push(File.basename(filename, ".rb"))
		end

		def init_modules
			classes = Revok::Modules.constants
			classes.each {|clazz|
				init_module(clazz)
			}
		end

		def init_module(clazz)
			begin
				symbol = Revok::Modules.const_get(clazz)
				if (!symbol.instance_methods(false).include?(:run))
					raise NotImplementedError, "#{symbol.to_s} is a invalid module definition", caller
				end
				instance = symbol.new
				if ((instance.name != nil) && (instance.class.superclass == Revok::Module))
					@modules[instance.name.to_s] = instance
				else
					raise NameError, "#{instance.class.name} is a invalid module definition", caller
				end
			rescue NameError, NotImplementedError, ArgumentError => exp
				Log.error(exp.to_s)
				Log.debug(exp.backtrace.join("\n"))
			end
		end

		attr_reader		:modules_loaded
		attr_reader		:load_error_modules
		attr_reader		:modules
		attr_accessor	:modules_path

		protected

			attr_writer		:load_error_modules
			attr_writer		:modules_loaded
			attr_writer		:modules
	end
end
