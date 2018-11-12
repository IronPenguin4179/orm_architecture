def update(ids, updates)
  if updates.values.first.is_a? (Hash)
    updates_hash = {}
    updates.map {|hash|
      updates_hash.merge(hash)
    }
  end
  updates_array = BlocRecord::Utility.convert_keys(updates_hash)
  updates_array.delete "id"
  array_of_updates = updates.map {|key, value|
    "#{key}=#{BlocRecord::Utility.sql_strings(value)}"
  }
  
  if ids.class == Fixnum
    where_clause = "WHERE id = #{ids};"
  elsif ids.class == Array
    where_clause = ids.empty? ? ";" : "WHERE id IN (#{ids.join(",")});"
  else
    where_clause = ";"
  end

  connection.execute <<-SQL
    UPDATE #{table}
    SET #{array_of_updates * ","} #{where_clause}
  SQL

  true

  puts updates_array
end

#people = { 1 => { "first_name" => "David" }, 2 => { "first_name" => "Jeremy" } }
#Person.update(people.keys, people.values)

