module PhotoFS
  module Data
    def self.consistent_arrays?(records, objects)
      if records.length == objects.length
        records.zip(objects).reduce(true) do |memo, pair|
          memo && pair[0].consistent_with?(pair[1])
        end
      else
        false
      end
    end

  end
end
