def order(*args)
  array_strings = []
  order_found = false
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
  
  strings = ""
  array_strings.map{ |item|
    if item.include?("DESC") || item.include?("desc")
      order = "DESC"
      puts "SELECT #{strings + item[0..-6]} FROM TABLE ORDER BY #{order};"
      strings = ""
      order_found = true
    elsif item.include?("ASC") || item.include?("asc")
      order = "ASC"
      puts "SELECT #{strings + item[0..-5]} FROM TABLE ORDER BY #{order};"
      strings = ""
      order_found = true
    else
      strings = strings + item + ","
    end
  }

  if order_found == false
    puts "SELECT #{strings.delete_suffix(",")} FROM TABLE ORDER BY ASC;"
  end
  puts "----------"

end

order(:name, phone_number: :desc)
order(name: :asc, phone_number: :desc)
order("name, boot, phone_number DESC, title asc")
order("name ASC","phone_number DESC")
order("name,phone_number,title")