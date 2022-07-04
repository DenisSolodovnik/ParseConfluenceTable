require "json"

json_filename = ARGV[0]
source_folder_path = ARGV[1]
$source_filename = ARGV[2]
$source_classname = ARGV[3]

json_file = File.open json_filename

def swiftHeader
  "//\n"\
  "//  %s.swift\n"\
  "//  Nomerogram\n"\
  "//\n"\
  "//  Created by ScriptColors %s.\n"\
  "//  Copyright © 2020 Amayama LLC. All rights reserved.\n"\
  "//\n\n" %[$source_filename, Time.new]
end

def swiftColors(colors)
  colors_code_string = ""
  for i in 0..colors.size - 1
    colors_code_string += colors[i].getSwiftCode(i < colors.size - 1)
  end

  "import UIKit\n"\
  "import DromUtils\n\n"\
  "@objcMembers final class %s: NSObject {\n"\
  "%s"\
  "}" %[$source_classname, colors_code_string]
end

class SourceColor
  @identifier = {}
  @colors_by_scheme = {}
  
  def getIdentifier
    @identifier
  end
  def setIdentifier=(value)
    @identifier = value
  end
  
  def getColorsByScheme
    @colors_by_scheme
  end
  def setColorsByScheme=(value)
    @colors_by_scheme = value
  end

  def getSwiftCode(needsNewLine)
    colors_code_string = ""
    newLine = needsNewLine ? "\n" : ""
    @colors_by_scheme.keys.sort { |a, b| b <=> a }.each do |scheme_name|
      if scheme_name == "light"
        comma = ", "
      else
        comma = ""
      end
      
      if @colors_by_scheme[scheme_name].end_with?("%") 
        alpha = @colors_by_scheme[scheme_name][-3,2].to_f / 100
        if alpha == 0.0
          resultAlpha = ""
          resultColor = ".clear"
        else
          resultAlpha = ".withAlphaComponent(%s)" % [alpha]
          resultColor = @colors_by_scheme[scheme_name][0,7] 
        end
      else
        resultAlpha = ""
        resultColor = @colors_by_scheme[scheme_name]
      end

      if resultColor.include? "clear"
        colors_code_string += "%s: %s%s" % [scheme_name, resultColor, comma]
      elsif (resultColor.include? "000000") or (resultColor.include? "FFFFFF")
        resultColor = (resultColor.include? "000000") ? ".black" : ".white"
        colors_code_string += "%s: %s%s%s" % [scheme_name, resultColor, resultAlpha, comma]
      else
        colors_code_string += "%s: .hex(\"%s\")%s%s" % [scheme_name, resultColor, resultAlpha, comma]
      end
    end
    "    static var %s: UIColor {\n"\
    "        .color(%s)\n"\
    "    }\n%s" % [@identifier, colors_code_string, newLine]
  end
end

colors_by_id = {}

color_schemes = JSON.load json_file

color_schemes.keys.each do |scheme_name|
  scheme_data = color_schemes[scheme_name]
  #puts scheme_name
  scheme_data["colors"].keys.each do |color_name|
    #puts color_name
    source_color = colors_by_id[color_name]
    if (source_color.nil?)
      source_color = SourceColor.new()
    end
    source_color.setIdentifier = color_name
    colors = source_color.getColorsByScheme()
    if (colors.nil?)
      colors = {}
    end
    colors[scheme_name] = scheme_data["colors"][color_name]
    source_color.setColorsByScheme = colors
    colors_by_id[color_name] = source_color
  end
end


source_filepath = File.join(source_folder_path, [$source_filename, ".swift"].join )
File.open(source_filepath, 'w') { |file|
  file.write(swiftHeader)
  file.write(swiftColors(colors_by_id.values))
}

json_file.close
