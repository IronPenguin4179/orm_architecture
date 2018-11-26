require 'sqlite3'
require 'pg'

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
    if start.is_a?(Integer) == false || batch.is_a?(Integer) == false
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
    if start.is_a?(Integer) == false || batch.is_a?(Integer) == false
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
    strings = ""
    order_found = false
    array_strings = []
    array_of_rows = []

    #Iterates through all args, identifies different entries, converts them to strings
    #and then adds each string to array_strings
    args.map { |arg|
      if arg.is_a?(String)
        while arg.include?(",")
          arg.strip!
          comma_index = arg.index(",")
          arg_slice = arg.slice!(0,comma_index+1).delete_suffix(",")
          array_strings.push(arg_slice)
        end
        array_strings.push(arg.strip)
      elsif arg.is_a?(Hash)
        arg.to_a.map { |pair|
          array_strings.push(pair.first.to_s + " " + pair.last.to_s)
        }
      elsif arg.is_a?(Symbol)
        array_strings.push(arg.to_s)
      end
    }
    
    #Iterates through each arg in array_strings and looks for a described order. If an 
    #item doesn't contain an order it is added to strings, and each iteration will add
    #to string until an order is found. Once order is found rows from SQL query are pushed
    #to array_of_rows.
    array_strings.map{ |item|
      if item.include?("DESC") || item.include?("desc")
        order = "DESC"

        column_names = strings + item[0..-6]
        rows = order_sql_connect(column_names,order)
        array_of_rows.push(rows)

        strings = ""
        order_found = true
      elsif item.include?("ASC") || item.include?("asc")
        order = "ASC"

        column_names = strings + item[0..-6]
        rows = order_sql_connect(column_names,order)
        array_of_rows.push(rows)

        strings = ""
        order_found = true
      else
        strings = strings + item + ","
      end
    }
  
    #If no order is given, gets rows from SQL with default order of ASC.
    if order_found == false
      column_names = strings.delete_suffix(",")
      rows = order_sql_connect(column_names,"ASC")
      array_of_rows.push(rows)
    end

    return array_of_rows
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
      when Hash
        assoc = args.shift
        rows = connection.execute <<-SQL
          SELECT * FROM #{table}
          INNER JOIN #{assoc.first} ON #{assoc.first}.#{table}_id = #{table}.id
          INNER JOIN #{assoc.last} ON #{assoc.last}.#{assoc.first}_id = #{assoc.first}.id
        SQL
      end
    end

    rows_to_array(rows)
  end

  def method_missing(m, *args, &block)
    if m.include?('find_by_')
      suffix = m.to_s.delete_prefix('find_by_')
      self.send("find_by",suffix.to_sym,*args)
    elsif m.include?('update_')
      suffix = m.to_s.delete_prefix('update_')
      self.send("update_attribute",suffix.to_sym,*args)
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
    collection = BlocRecord::Collection.new
    rows.each { |row| collection << new(Hash[columns.zip(row)]) }
    collection
  end

  def input_error
    raise "An input error has occured."
  end

  #For use in order, takes a string of column names and a string of order,
  #inserts them into SQL, and returns an array containing rows.
  def order_sql_connect(column_names, order)
    rows = connection.execute <<-SQL
      SELECT #{column_names} FROM #{table}
      ORDER BY #{order};
    SQL
    rows_to_array(rows)
  end
end