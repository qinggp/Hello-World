module ActionView
  module Helpers
    module TranslationHelper
      # safe_record, safe_erb で taint された String をキャッチしてしま
      # うため，untaintする． I18n 用
      def translate_with_untaint(key, options = {})
        return translate_without_untaint(key, options).dup.untaint
      end
      alias_method_chain :translate, :untaint
      alias :t :translate_with_untaint
    end
  end
end

module ActionController
  module Translation
    # safe_record, safe_erb で taint された String をキャッチしてしま
    # うため，untaintする． I18n 用
    def translate_with_untaint(key, options = {})
      return translate_without_untaint(key, options).dup.untaint
    end
    alias_method_chain :translate, :untaint
    alias :t :translate_with_untaint
  end
end
