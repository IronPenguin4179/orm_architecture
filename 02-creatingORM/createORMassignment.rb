def underscore(camel_cased_word)
  string = camel_cased_word.gsub(/::/, '/')
  string.gsub!(/([A-Z]+)([A-Z][a-z])/,'\1_\2')
  string.gsub!(/([a-z\d])([A-Z])/,'\1_\2')
  string.tr!("-", "_")
  string.downcase
end

def camel_case(snake_cased_word)
  string = snake_cased_word.gsub(/::/, '/')
  snake_cased_word.gsub!(/(\_)([A-z])/) { |s| s.upcase}
  snake_cased_word.tr!('_','')
end
#--------------------------------------------------