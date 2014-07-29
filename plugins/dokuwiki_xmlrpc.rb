#
# This cinch plugin is part of EV0002
#
# written by carstene1ns <dev @ f4ke . de> 2014
# available under MIT license
#

require "xmlrpc/client"

class Cinch::DokuwikiXMLRPC
  include Cinch::Plugin

  listen_to :connect, :method => :startup
  match /wiki search (.+)/, :method => :wiki_search
  match "wiki"

  def startup(*)
    @server = XMLRPC::Client.new3(config)

    # circumventing a ruby bug: content-length is wrong for compressed server responses
    #   https://bugs.ruby-lang.org/issues/8182
    @server.http_header_extra = { "accept-encoding" => "identity" }
  end

  def wiki_search(msg, search)

    success, res = @server.call2("dokuwiki.search", search)

    if success
      if res.empty?
        message = "No results."
      else
        url = config[:wiki_url] + res[0]["id"].gsub(/:/, "/")

        message = "Found "
        # only one result
        unless res.length == 1
          message << "#{res.length.to_s} results, first is "
        end
        message << "\"#{res[0]["title"]}\": " + url
      end
    else
      puts "Error: #{res.faultCode} #{res.faultString}"
      message = "The request did return an error."
    end
    msg.reply "[wiki] #{message}"
  end

  def execute(msg)
    msg.reply config[:wiki_url]
  end

end
