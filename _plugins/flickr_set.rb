# Flickr Set Tag.
#
# Generates image galleries from a Flickr set.
#
# Usage:
#
#   {% flickr_set flickr_username flickr_set_id %}
#
# Example:
#
#   {% flickr_set tsmango 72157625102245887 %}
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
#
# By default, thumbnails are linked to their corresponding Flickr page.
# If you override a_href with a size ('s', 'm', etc), the thumbnail will
# link to that size image. This is useful in combination with the image_rel
# parameter and a lightbox gallery.
#
# Author: Thomas Mango
# Site: http://thomasmango.com
# Plugin Source: http://github.com/tsmango/jekyll_flickr_set_tag
# Site Source: http://github.com/tsmango/thomasmango.com
# Plugin License: MIT

require 'net/https'
require 'nokogiri'
require 'uri'
require 'json'

module Jekyll
  class FlickrSetTag < Liquid::Tag
    def initialize(tag_name, config, token)
      super

      @user = config.split[0]
      @set  = config.split[1]

      @config = Jekyll.configuration({})['flickr_set'] || {}

      @config['gallery_tag']   ||= 'p'
      @config['gallery_class'] ||= 'gallery'
      @config['a_href']        ||= nil
      @config['a_target']      ||= '_blank'
      @config['image_rel']     ||= ''
      @config['image_size']    ||= 's'
    end

    def render(context)
      <<-EOF
      <#{@config['gallery_tag']} class="#{@config['gallery_class']}">
        #{photos.collect{|photo| render_thumbnail(photo)}}
      </#{@config['gallery_tag']}>
      EOF
    end

    def render_thumbnail(photo)
      <<-EOF
      <a href="#{photo.url(@config['a_href'])}" target="#{@config['a_target']}">
        <img src="#{photo.thumbnail_url}" rel="#{@config['image_rel']}"/>
      </a>
      EOF
    end

    def photos
      @photos = Array.new

      JSON.parse(json)['items'].each do |item|
        @photos << FlickrPhoto.new(item['title'], item['link'], item['media']['m'], @config['image_size'])
      end

      @photos.sort
    end

    # Using the given Flickr username and set id, get the location of the set's
    # atom feed. Using the atom feed's location, fetch the json feed.
    #
    # Note: It would have been faster to just require the nsid be given, but
    # it's easier to use this tag if the flickr username is given instead.
    def json
      uri  = URI.parse("http://www.flickr.com/photos/#{@user}/sets/#{@set}/")
      http = Net::HTTP.new(uri.host, uri.port)
      doc  = Nokogiri::HTML(http.request(Net::HTTP::Get.new(uri.request_uri)).body)

      url  = doc.css('head link[@rel=alternate]').first['href']

      url.gsub!(/format=atom/,    'format=json&nojsoncallback=1')
      url.gsub!(/format=rss_200/, 'format=json&nojsoncallback=1')

      uri  = URI.parse(url)
      http = Net::HTTP.new(uri.host, uri.port)

      return http.request(Net::HTTP::Get.new(uri.request_uri)).body
    end
  end

  class FlickrPhoto

    def initialize(title, url, thumbnail_url, thumbnail_size)
      @title          = title
      @url            = url
      @thumbnail_url  = thumbnail_url.gsub(/_m\.jpg/i, "_#{thumbnail_size}.jpg")
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