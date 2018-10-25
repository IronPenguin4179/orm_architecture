string = "name ,phone_number ASC"

slice = string.slice!(/(DE|A)SC/)

puts "This is string: #{string}"
puts "This is slice: #{slice}"