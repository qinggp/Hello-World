module ActionView::Helpers::AssetTagHelper

  # vendor/plugins/theme_support/lib/helpers/rhtml_theme_tags.rb に定義されている。
  def theme_image_path( source, theme=nil )
    theme = theme || controller.current_theme
    # origin: compute_public_path(source, "themes/#{theme}/images", 'png')
    compute_public_path(source, "themes/#{theme}/images")
  end
end
