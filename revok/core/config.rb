module Revok

	class Config < Hash
		
		Defaults =
			{
				'ModulesDirectory'		=> "modules"
			}

		def self.modules_directory
			return self.new.module_directory
		end
	end

end
