# -*- coding: utf-8 -*-
require 'json'
require 'net/http'

# Title: ScSoundCloud plugin for Jekyll
# Author: tcnsm

module Jekyll
  class ScSoundCloud < Liquid::Tag
    def initialize(tag_name, url, tokens)          
        @url = url if /^https/ =~ url
    end

    def render(context)
      if @url
        "<a href=\"#{@url}\" class=\"sc-player\"></a>"
      else
        "Error: invalid url"
      end
    end
  end
end

Liquid::Template.register_tag('snd', Jekyll::ScSoundCloud)

