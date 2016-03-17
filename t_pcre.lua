rex_pcre = require "rex_pcre"

print( rex_pcre.new("[0-9]+"):exec("1234") )
print( rex_pcre.new("\\d+"):exec("hello1234") )