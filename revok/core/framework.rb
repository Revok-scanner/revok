module Revok

	class Framework
		def initialize()
			self.datastore = Hash.new
			self.modules = Array.new
			self.load_error_modules = Array.new
			self.modules_loaded = Array.new
		end

		def init_module_path
			if (Dir.exist?(Revok::Config.mudule_directory))
				self.datastore['ModulesPath'] = Revok::Config.mudule_directory
			end
		end

		def load_modules
			path = self.datastore['ModulesPath'].to_s + '/'
			begin
				if (Dir.exist?(path))
					Dir.foreach(path) {|filename|
						next if (filename[0] == '.')
						next if (File.extname(filename) != ".rb")
						begin
							load_module(path + filename)
							self.modules_loaded.push(File.basename(filename, ".rb"))
						rescue IOError
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

		def load_module(file_path)
			file = File.read(file_path)
			Revok.module_eval file
		end

		def init_modlue

		end
	end

	attr_reader		:datastore
	attr_reader		:modules

	protected

		attr_writer		:datastore
		attr_writer		:modules
		attr_accessor	:load_error_modules
		attr_accessor|  :modules_loaded
end
