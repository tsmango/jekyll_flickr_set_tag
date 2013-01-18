# Flickr Set Tag.
#
# Generates image galleries from a Flickr set.
#
# Usage:
#
#   {% flickr_set flickr_set_id %}
#
# Example:
#
#   {% flickr_set 72157625102245887 %}
#
# Default Configuration (override in _config.yml):
#
#   flickr_set:
#     gallery_tag:   'p'
#     gallery_class: 'gallery'
#     a_href:        nil
#     a_target:      '_blank'
#     image_rel:     ''
#     image_size:    's'
#     api_key:       ''
#
# By default, thumbnails are linked to their corresponding Flickr page.
# If you override a_href with a size ('s', 'm', etc), the thumbnail will
# link to that size image. This is useful in combination with the image_rel
# parameter and a lightbox gallery.
#
# You must provide an API Key in order to query Flickr. It must be configured in _config.yml.
#
# Author: Thomas Mango
# Site: http://thomasmango.com
# Plugin Source: http://github.com/tsmango/jekyll_flickr_set_tag
# Site Source: http://github.com/tsmango/thomasmango.com
# Plugin License: MIT

require 'net/https'
require 'uri'
require 'json'

module Jekyll
  class FlickrSetTag < Liquid::Tag
    def initialize(tag_name, config, token)
      super

      @set  = config.strip

      @config = Jekyll.configuration({})['flickr_set'] || {}

      @config['gallery_tag']   ||= 'p'
      @config['gallery_class'] ||= 'gallery'
      @config['a_href']        ||= nil
      @config['a_target']      ||= '_blank'
      @config['image_rel']     ||= ''
      @config['image_size']    ||= 's'
      @config['api_key']       ||= ''
    end

    def render(context)
      html = "<#{@config['gallery_tag']} class=\"#{@config['gallery_class']}\">"

      photos.each do |photo|
        html << "<a href=\"#{photo.url(@config['a_href'])}\" target=\"#{@config['a_target']}\">"
        html << "  <img src=\"#{photo.thumbnail_url}\" rel=\"#{@config['image_rel']}\"/>"
        html << "</a>"
      end

      html << "</#{@config['gallery_tag']}>"

      return html
    end

    def photos
      @photos = Array.new

      JSON.parse(json)['photoset']['photo'].each do |item|
        @photos << FlickrPhoto.new(item['title'], item['id'], item['secret'], item['server'], item['farm'], @config['image_size'])
      end

      @photos.sort
    end

    def json
      uri  = URI.parse("http://api.flickr.com/services/rest/?method=flickr.photosets.getPhotos&photoset_id=#{@set}&api_key=#{@config['api_key']}&format=json&nojsoncallback=1")
      http = Net::HTTP.new(uri.host, uri.port)
      return http.request(Net::HTTP::Get.new(uri.request_uri)).body
    end
  end

  class FlickrPhoto

    def initialize(title, id, secret, server, farm, thumbnail_size)
      @title          = title
      @url            = "http://farm#{farm}.staticflickr.com/#{server}/#{id}_#{secret}.jpg"
      @thumbnail_url  = url.gsub(/\.jpg/i, "_#{thumbnail_size}.jpg")
      @thumbnail_size = thumbnail_size
    end

    def title
      return @title
    end

    def url(size_override = nil)
      return (size_override ? @thumbnail_url.gsub(/_#{@thumbnail_size}.jpg/i, "_#{size_override}.jpg") : @url)
    end

    def thumbnail_url
      return @thumbnail_url
    end

    def <=>(photo)
      @title <=> photo.title
    end
  end
end

Liquid::Template.register_tag('flickr_set', Jekyll::FlickrSetTag)
