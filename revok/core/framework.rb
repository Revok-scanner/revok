require_relative 'config'
require_relative 'module'
require_relative 'modules'

module Revok

	class Framework
		def initialize
			self.load_error_modules = Array.new
			self.modules_loaded = Array.new
		end

		def init_module_path
			if (Dir.exist?(Revok::Config.mudule_directory))
				DATASTORE['ModulesPath'] = Revok::Config.mudule_directory
			end
		end

		def load_modules
			path = DATASTORE['ModulesPath'].to_s + '/'
			begin
				if (Dir.exist?(path))
					Dir.foreach(path) {|filename|
						next if (filename[0] == '.')
						next if (File.extname(filename) != ".rb")
						begin
							load_module(path, filename)
						rescue IOError, NameError
							self.load_error_modules.push(path + filename)
						end
					}
				else
					raise RuntimeError, "The directory of moudles is invalid", caller
				end

				if (!self.load_error_modules.empty?)
					puts("Some modules are failed to load: #{self.load_error_modules.to_s}")
					return false
				end

				return true
			rescue RuntimeError => exp
				# Temporary function to output
				puts(exp.to_s)
			end
		end

		def load_module(path, filename)
			file = File.read(path + filename)
			Revok::Modules.module_eval file
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
				instance = Revok::Modules.const_get(clazz).new
				if ((instance.name != nil) && (instance.class.superclass == Revok::Module))
					MODULES[instance.name.to_s] = instance
				else
					raise NameError, "#{instance.class.name} is a invalid module definition", caller
				end
			rescue NameError => exp
				# Temporary function to output
				puts(exp.to_s)
			end
		end

		protected

			attr_accessor	:load_error_modules
			attr_accessor	:modules_loaded
	end
end
