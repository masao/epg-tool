#!/usr/bin/env ruby
# $Id$

# require "rss"
require "rexml/document"
require "open-uri"
require "kconv"
require "uri"
require "fileutils"

module Nikkan
   def get_all_iepg( area )
      rss_url = "http://tv.nikkansports.com/tv.php?mode=04&site=007&lhour=2&category=g&template=rss&area=#{ area }&pageCharSet=UTF8"
      cont = open( rss_url ){|io| io.read }
      doc = REXML::Document.new( cont )
      doc.elements.each( "//item" ) do |item|
         # puts item.text("./title").toeuc
         url = item.text("./link")
         params = URI.parse( url ).query.split(/&/)
         params_hash = Hash[ *params.map{|e| e.split(/\=/) }.flatten ]
         # p params_hash
         date = params_hash[ "sdate" ]
         time = params_hash[ "shour" ] + params_hash[ "sminutes" ]
         station = params_hash[ "station" ]

         program_url = url + "&area=#{ area }"
         cont = open( program_url ){|io| io.read }

         filename = File.join( area, date, station, "#{time}.html" )
         dir = File.dirname( filename )
         FileUtils.mkdir_p( dir )
         open( filename, "w" ){|io| io.puts cont }

         if /<a href="(\/iepg\.php\?.*)">/ =~ cont
            path = $1
            iepg_url = "http://tv.nikkansports.com#{ path }"
            cont = open( iepg_url ){|io| io.read }
            filename = File.join( area, date, station, "#{time}.iepg" )
            open( filename, "w" ){|io| io.puts cont }
         else
            raise "iepg link not found!"
         end
      end
   end
end

if $0 == __FILE__
   include Nikkan
   # ( "001" .. "002" ).each do |area|
   ( "001" .. "047" ).each do |area|
      get_all_iepg( area )
   end
end
