# Flickr Set Tag

Generates image galleries from a Flickr set.

Usage:

    {% flickr_set flickr_set_id %}

Example:

    {% flickr_set 72157625102245887 %}

Default Configuration (override in _config.yml):

    flickr_set:
      gallery_tag:   'p'
      gallery_class: 'gallery'
      a_href:        nil
      a_target:      '_blank'
      image_rel:     ''
      image_size:    's'
      api_key:       ''

By default, thumbnails are linked to their corresponding Flickr page.
If you override a_href with a size ('s', 'm', etc), the thumbnail will
link to that size image. This is useful in combination with the image_rel
parameter and a lightbox gallery.

You must provide an API Key in order to query Flickr. It must be configured in _config.yml.