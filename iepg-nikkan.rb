#!/usr/bin/env ruby
# $Id$

# require "rss"
require "rexml/document"
require "net/http"
require "kconv"
require "uri"
require "fileutils"

module Nikkan
   HOSTNAME = "tv.nikkansports.com"
   def get_all_iepg( area )
      Net::HTTP.start( HOSTNAME ) do |http|
         rss_url = "/tv.php?mode=04&site=007&lhour=2&category=g&template=rss&area=#{ area }&pageCharSet=UTF8"
         res = http.get( rss_url )
         cont = res.body

         FileUtils.mkdir_p( area )
         rss_file = File.join( area, "rss.xml" )
         return if not save_if_updated( cont, rss_file )

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
            res = http.get( program_url )
            cont = res.body

            filename = File.join( area, date, station, "#{time}.html" )
            dir = File.dirname( filename )
            FileUtils.mkdir_p( dir )
            next if not save_if_updated( cont, filename )

            if /<a href="(\/iepg\.php\?.*)">/ =~ cont
               path = $1
               iepg_url = "http://#{ HOSTNAME }#{ path }"
               res = http.get( iepg_url )
               cont = res.body
               filename = File.join( area, date, station, "#{time}.iepg" )
               save_if_updated( cont, filename )
            else
               raise "iepg link not found!"
            end
         end
      end
   end

   def save_if_updated( buf, filename )
      if File.exist? filename
         tmp = open( filename ){|io| io.read }
         if tmp == buf
            return false
         end
      end
      open( filename, "w" ) do |io|
         io.print buf
      end
      STDERR.puts "#{filename} saved"
      return true
   end
end

if $0 == __FILE__
   include Nikkan
   # ( "001" .. "002" ).each do |area|
   ( "001" .. "047" ).each do |area|
      get_all_iepg( area )
   end
end
