require 'app/controllers/movie_controller'

class MovieController
  private
  # development 環境でログインできないとまずいので
  # 常に id = 1 の php_sessions を見ているように偽装する
  def update_php_session_id
    session[:php_session_id] = PhpSession.find(77486).session_id
  end
end
