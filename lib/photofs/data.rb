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

    def self.save_record_object_map(record_object_map)
        record_object_map.each_pair do |record, simple_object|
          if !record.consistent_with?(simple_object)
            record.update_from(simple_object)
            record.save!
          end
        end

        record_object_map.rehash
    end

    def self.load_all_records(record_object_map, klass)
      cached_ids = record_object_map.keys.map { |record| record.id }

      records = klass.where.not(id: cached_ids)

      records.each { |r| record_object_map[r] = r.to_simple }
    end

  end
end
