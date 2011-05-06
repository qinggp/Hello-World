require File.dirname(__FILE__) + '/../test_helper'
require 'movies_controller'

class MoviesControllerWithTransactionTest < ActionController::TestCase
  # トランザクションを含むテストを行うため
  # フィクスチャロードは通常の処理で行う
  self.use_transactional_fixtures = false

  def setup
    @controller = MoviesController.new
    @user = users(:sns_tarou)
    @another = users(:sns_hanako)
    @request.session_options[:id] = "TEST_SESSION_ID"
    login_as(@user)
  end

  def test_create_failure_without_temporary_file
    movie = Movie.plan(
      :title => 'test title',
      :body => 'test comment'
    )

    movie_count = Movie.count
    my_movie_count = @user.movies(true).count

    put(:create, :movie => movie)

    assert_response(:redirect)
    assert_redirected_to(:action => 'failure_upload')
    assert_equal(movie_count, Movie.count)
    assert_equal(my_movie_count, @user.movies(true).count)
    @movie = Movie.find_by_title(movie[:title])
    assert_nil(@movie)
    assert_redirected_to(:action => 'failure_upload')
  end
end
