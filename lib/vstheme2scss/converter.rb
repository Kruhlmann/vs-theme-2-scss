require "json"
require "pathname"


module Converter

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

  def theme_files_to_hash(themes)
    themes.map{ |theme_file|
      theme_path = Pathname.new(theme_file)
      theme = nil
      if not theme_path.directory?
        theme = JSON.parse(theme_path.read)
      else
        puts "Error: #{theme_path.dirname}#{theme_path.basename} was not a file."
      end
      theme
    }.select{ |theme| theme != nil }
  end

  def get_theme_logic()
    "\n" + '@mixin themify($themes) {' + "\n"\
    '    @each $theme, $map in $themes {' + "\n"\
    '        .theme-#{$theme} & {' + "\n"\
    '            $theme-map: () !global;' + "\n"\
    '            @each $key, $submap in $map {' + "\n"\
    '                $value: map-get(map-get($themes, $theme), "#{$key}");' + "\n"\
    '                $theme-map: map-merge($theme-map, ($key: $value)) !global;' + "\n"\
    '            }' + "\n"\
    '            @content;' + "\n"\
    '            $theme-map: null !global;' + "\n"\
    '        }' + "\n"\
    '    }' + "\n"\
    '}' + "\n"\
    '' + "\n"\
    '@function themed($key) {' + "\n"\
    '    @return map-get($theme-map, $key);' + "\n"\
    '}'
  end

  def make_files(options, themes)
    if not options[:out_file]
        puts "Error: Missing output file"
        exit
    end

    theme_logic = get_theme_logic()
    out_path = Pathname.new(options[:out_file])
    json_res = theme_files_to_hash(themes)
    out_res = json_res.map{ |theme| build_scss_theme(theme) }.join("\n")
    out_path.write("$themes: (\n#{out_res}\n);\n#{theme_logic}")

    if options[:json_list]
      json_out_path = Pathname.new(options[:json_list])
      if json_out_path.directory?
        puts "Error #{json_out_path.dirname}#{json_out_path.basename} is not a file"
      else
        names = json_res.map{ |theme| "#{theme["name"].downcase.gsub(/ /, "-")}" }
        json_out_path.write(names)
      end
    end
  end

end
