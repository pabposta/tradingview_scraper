require 'rubygems'
require 'HTTParty'
require 'Nokogiri'

# get command line arguments
if ARGV.length != 3
  puts 'Usage: main.rb source_url server_url cutoff_hours'
  exit
end

source_url = ARGV[0]
server_url = ARGV[1]
cutoff_hours = ARGV[2].to_i * 3600

# calculate cutoff timestamp
cutoff = Time.now.to_f - cutoff_hours

# get the page
page = HTTParty.get(source_url)
html = Nokogiri::HTML(page)

# extract ideas
ideas = html.css('.tv-site-widget.tv-widget-idea').map { |idea_element|
  timestamp = idea_element.css('.tv-widget-idea__time')[0]['data-timestamp'].to_f
  ticker = idea_element.css('.tv-widget-idea__symbol')[0].text
  { timestamp: timestamp, ticker: ticker }
}.select { |idea|
  idea[:timestamp] > cutoff
}.map { |idea|
  {
    tickers: {
      tradingview: idea[:ticker]
    },
    streams: ['default'],
    time: Time.at(idea[:timestamp]).utc.strftime('%Y-%m-%d')
  }
}

# send the ideas to the server
responses = ideas.map { |idea|
  HTTParty.post(server_url, body: idea.to_json, headers: { 'Content-Type': 'application/json' })
}

puts responses
