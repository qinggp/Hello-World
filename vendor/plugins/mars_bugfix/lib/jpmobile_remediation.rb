module ActionController
  Base.class_eval do
    def redirect_to_full_url(url, status)
      if apply_trans_sid? and !url.match(/#{session_key}/) and jpmobile_session_id  #ここ
        uri = URI.parse(url)
        if uri.query
          uri.query += "&#{session_key}=#{jpmobile_session_id}"
        else
          uri.query = "#{session_key}=#{jpmobile_session_id}"
        end
        url = uri.to_s
      end

      redirect_to_full_url_without_jpmobile(url, status)
    end
  end
end

module Jpmobile::TransSid
  def aenppend_session_id_parameter
    return unless request # for test process
    return unless apply_trans_sid?
    return unless jpmobile_session_id #ここ
    response.body.gsub!(%r{(</form>)}i, sid_hidden_field_tag+'\1')
  end
end
