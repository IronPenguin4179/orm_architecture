module BlocRecord
  class Collection < Array
    def update_all(updates)
      ids = self.map(&:id)
      self.any? ? self.first.class.update(ids, updates) : false
    end

    def where(*args)
      self.class.where(args)
    end

    def take(n=1)
      new_array = self.shift(n)
      return new_array
    end

    def not(*args)
      if args.count > 1
        expression = args.shift
        params = args
      else
        case args.first
        when String
          expression = args.first
        end
        when Hash
          expression_hash = BlocRecord::Utility.convert_keys(args.first)
          expression = expression_hash.map {|key, value| "#{key}!=#{BlocRecord::Utility.sql_strings(value)}"}.join(" and ")
        end
      end 
  
      sql = <<-SQL
        SELECT #{columns.join ","} FROM #{table}
        WHERE #{expression};
      SQL
  
      rows = connection.execute(sql, params)
      rows_to_array(rows)
    end

    def destroy_all
      ids = self.map(&:id)
      self.any? ? self.first.class.destroy(ids) : false
    end
  end
end

