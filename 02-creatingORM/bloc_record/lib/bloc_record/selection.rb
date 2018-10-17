require 'sqlite3'

module Selection
  def find(*ids)
    ids.map {|id|
      id = id.abs
    }

    if ids.length == 1
      find_one(ids.first)
    else
      rows = connection.execute <<-SQL
        SELECT #{columns.join ","} FROM #{table}
        WHERE id IN (#{ids.join(",")});
      SQL

      rows_to_array(rows)
    end 
  end

  def find_one(id)
    if id.is_a?(Integer)
      row = connection.get_first_row <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      WHERE id = #{id.abs};
      SQL
      init_object_from_row(row)
    else
      input_error()
    end
  end

  def find_by(attribute, value)
    if attribute.is_a?(Symbol)
      rows = connection.execute(<<-SQL)
        SELECT #{columns.join ","} 
        FROM #{table}
        WHERE #{attribute} = #{BlocRecord::Utility.sql_strings(value)};
      SQL
      rows_to_array(rows)
    else
      input_error()
    end
  end

  def find_each(start=0,batch=start)
    if start.is_a?(Integer) = false || batch.is_a?(Integer) = false
      input_error()
    end
    
    size = start
    
    while size > 0 
      rows = connection.execute <<-SQL
        SELECT #{columns.join ","} FROM #{table}
        ORDER BY #{id}
        LIMIT #{start.abs} OFFSET #{(start-size).abs};
      SQL

      rows_to_array(rows)

      rows.each do |row|
        yield(row)
      end

      size -= batch
    end
  end

  def find_in_batches(start=0, batch=start)
    if start.is_a?(Integer) = false || batch.is_a?(Integer) = false
      input_error()
    end
    
    size = start
    
    while size > 0 
      rows = connection.execute <<-SQL
        SELECT #{columns.join ","} FROM #{table}
        ORDER BY #{id}
        LIMIT #{start.abs} OFFSET #{(start-size).abs};
      SQL

      rows_to_array(rows)

      yield(row)

      size -= batch
    end  
  end
  
  def take(num=1)
    if num.is_a?(Integer) 
      if num.abs > 1
        rows = connection.execute <<-SQL
          SELECT #{columns.join ","} FROM #{table}
          ORDER BY random()
          LIMIT #{num.abs};
        SQL

        rows_to_array(rows)
      else
        take_one
      end
    else
      input_error()
    end
  end

  def take_one
    row = connection.get_first_row <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      ORDER BY random()
      LIMIT 1;
    SQL

    init_object_from_row(row)
  end

  def first
    row = connection.get_first_row <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      ORDER BY id ASC LIMIT 1;
    SQL

    init_object_from_row(row)
  end

  def last
    row = connection.get_first_row <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      ORDER BY id DESC LIMIT 1;
    SQL

    init_object_from_row(row)
  end

  def all
    rows = connection.execute <<-SQL
      SELECT #{columns.join ","} FROM #{table};
    SQL

    rows_to_array(rows)
  end

  def where(*args)
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
        expression = expression_hash.map {|key, value| "#{key}=#{BlocRecord::Utility.sql_strings(value)}"}.join(" and ")
      end
    end 

    sql = <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      WHERE #{expression};
    SQL

    rows = connection.execute(sql, params)
    rows_to_array(rows)
  end

  def order(*args)
    if args.count > 1
      order = args.join(",")
    else
      order = args.first.to_s
    end

    rows = connection.execute <<-SQL
      SELECT * FROM #{table}
      ORDER BY #{order};
    SQL
    rows_to_array(rows)
  end

  def join(*args)
    if args.count > 1
      joins = args.map { |arg| "INNER JOIN #{arg} ON #{arg}.#{table}_id = #{table}.id"}.join(" ")
      rows = connection.execute <<-SQL
        SELECT * FROM #{table} #{joins}
      SQL
    else
      case args.first
      when String
        rows = connection.execute <<-SQL
          SELECT * FROM #{table} #{BlocRecord::Utility.sql_strings(args.first)};
        SQL
      when Symbol
        rows = connection.execute <<-SQL
          SELECT * FROM #{table}
          INNER JOIN #{args.first} ON #{args.first}.#{table}_id = #{table}.id
        SQL
      end
    end

    rows_to_array(rows)
  end

  def method_missing(m, *args, &block)
    if m.include?('find_by_')
      suffix = m.to_s.delete_prefix('find_by_')
      self.send("find_by",suffix.to_sym,*args)
    else
      raise "Method missing error."
    end
  end

  private  
  def init_object_from_row(row)
    if row
      data = Hash[columns.zip(row)]
      new(data)
    end
  end

  def rows_to_array(rows)
    rows.map { |row| new(Hash[columns.zip(row)]) }
  end

  def input_error
    raise "An input error has occured."
  end
end