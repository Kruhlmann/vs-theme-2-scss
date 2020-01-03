#!/usr/bin/env ruby
require "json"
require "pathname"
require "optparse"
require "ostruct"

def build_tokens_scss(tokens)
  tokens.select{ |token|
    token.key?("name")
  }.uniq{ |token|
    token["name"]
  }.select{ |token|
    not token["name"].include? "[" and not token["name"].include? "]" and not token["name"].include? "/"
  }.select{ |token|
    token["settings"].key?("foreground")
  }.map{ |token|
    "\t\t#{token["name"].downcase.gsub(/ /, "-")}-color: #{token["settings"]["foreground"]},"
  }.join("\n")
end

def build_scss_theme(theme)
  colors = theme["colors"]
  tokens = theme["tokenColors"]
  [
    "\t#{theme["name"].downcase.gsub(/ /, "-")}: (",
    "\t\tbackground-color: #{colors["editor.background"]},",
    "\t\tforeground-color: #{colors["editor.foreground"]},",
    "#{build_tokens_scss(tokens)}",
  ].join("\n") + "\n\t),"
end

options = OpenStruct.new
OptionParser.new do |parser|
  parser.banner = "Usage: vstheme2scss [options] <files>"
  parser.on("-j", "--json-list=JSONFILE", "File to output theme names to"){ |o| options[:json_list] = o }
  parser.on("-o", "--out-file=OUTFILE", "Output destionation file"){ |o| options[:out_file] = o }
end.parse!

if not options[:out_file]
  puts "Error: Missing output file"
  exit
end


out_path = Pathname.new(options[:out_file]);
json_res = ARGV.map{ |theme_file|
  theme_path = Pathname.new(theme_file)
  if not theme_path.directory?
    theme = JSON.parse(theme_path.read)
    scss_stub = build_scss_theme(theme)
  else
    puts "Error: #{theme_path.dirname}#{theme_path.basename} was not a file."
  end
  theme_path.directory? ? nil : JSON.parse(theme_path.read)
}.select{ |theme| theme != nil }

out_res = json_res.map{ |theme| build_scss_theme(theme) }.join("\n")
out_path.write("$themes: (\n#{out_res}\n);\n")

if options[:json_list]
  json_out_path = Pathname.new(options[:json_list])
  if json_out_path.directory?
    puts "Error #{json_out_path.dirname}#{json_out_path.basename} is not a file"
  else
    names = json_res.map{ |theme| "#{theme["name"].downcase.gsub(/ /, "-")}" }
    json_out_path.write(names)
  end
end