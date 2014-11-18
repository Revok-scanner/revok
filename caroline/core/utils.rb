require 'json'

module Revok
  class Utils

    def self.merge(source_a, source_b)
      composite = {}
      hash = JSON.parse(source_a.sub(/[^{]*/,''), {create_additions:false})
      hash.keys.each do |key|
        composite[key] = hash[key]
      end
      hash = JSON.parse(source_b.sub(/[^{]*/,''), {create_additions:false})
      hash.keys.each do |key|
        composite[key] = hash[key]
      end
      return JSON.dump(composite).to_s
    end

  end
end
