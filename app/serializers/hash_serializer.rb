class HashSerializer
    def self.dump(hash)
        hash
    end

    def self.load(hash)
       if hash == "{}"
        hash = {}
       end 
        (hash || {}).with_indifferent_access
    end
end
  