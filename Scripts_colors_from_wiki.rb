require 'json'
require 'nokogiri'
require 'net/http'
require 'uri'

class Confluence
  attr_accessor :user, :pass, :url
  def initialize(user, pass, url)
    self.user = user
    self.pass = pass
    self.url = url
  end

  def main_params_by_id(id)
    params = {expand: "body.view,version,container"}
    uri = URI.parse(url + "/rest/api/content/" + id)
    uri.query = URI.encode_www_form(params)

    request = Net::HTTP::Get.new(uri)
    request.basic_auth(user,pass)
    req_option = {
        use_ssl: uri.scheme == "https",
    }

    response = Net::HTTP.start(uri.hostname, uri.port, req_option) do |http|
      http.request(request)
    end
    json = JSON.parse(response.body)
    {
        version: json['version']['number'],
        title: json['title'],
        type: json['type'],
        html: json['body']['view']['value']
    }
  end
end

def parse_confluence_html(html)
  doc = Nokogiri::HTML.parse(html)
  table = doc.css('table.relative-table').first
  rows = table.css('tr')
  all_rows = rows.map do |row|
    row_values = row.css('td')
    heading = false
    if row_values.empty?
      row_values  = row.css('th')
      heading = true
    end
    [heading, row_values]
  end
  return all_rows
end

def color_scheme_from_rows(all_rows)
  color_scheme = {
      light: {
          appearance: "light",
          colors:{}
      },
      dark: {
          appearance: "dark",
          colors:{}
      }
  }

  all_rows.each do |row|
    if row[0] == false
      color_row = row[1]
      if color_row.count > 4
        light_color = color_row[2].text
        dark_color = color_row[3].text
        if check_color_text_to_valid?(light_color) && check_color_text_to_valid?(dark_color)
          color_scheme[:light][:colors][color_row[1].text] = light_color
          color_scheme[:dark][:colors][color_row[1].text] = dark_color
        end
      end
    end
  end
  return color_scheme
end

def check_color_text_to_valid?(color_text)
  !!(color_text =~ /([#][[:xdigit:]]{6})(?:[[:space:]]([0-9][0-9]?[%])|$)$/)
end

base_url = 'https://wiki.farpost.net'
user = ARGV[0]
pass = ARGV[1]
id = ARGV[2]
json_name = ARGV[3]

confluence = Confluence.new(user,pass,base_url)

main_page_params = confluence.main_params_by_id(id)
#puts main_page_params

html = main_page_params[:html]
all_rows = parse_confluence_html(html)
#puts all_rows

color_scheme = color_scheme_from_rows(all_rows)
#puts color_scheme

File.open(json_name,"w") do |f|
  f.write(JSON.pretty_generate(color_scheme))
end
