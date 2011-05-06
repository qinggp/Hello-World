module Mars::ActionView::Helpers::TextHelper
  def self.included(recipient)
    recipient.class_eval {
      remove_const(:AUTO_LINK_RE) if defined?(:AUTO_LINK_RE)
      const_set(:AUTO_LINK_RE,
                %r{
                 ( https?:// | www\. )
                   [^\s < \xc0-\xdf \xe0-\xef \xf0-\xf7 \xf8-\xfb \xfc-\xfd]+
                   }xn
                )
    }
  end
end
