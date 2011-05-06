require File.dirname(__FILE__) + '/../test_helper'
require 'fileutils'

class MoviesControllerTest < ActionController::TestCase
  # テスト用アップロードファイルパス
  TEST_FILE_PATH = File.join(RAILS_ROOT, 'public', 'images', 'rails.png')

  def setup
    @user = users(:sns_tarou)
    @another = users(:sns_hanako)
    @request.session_options[:id] = "TEST_SESSION_ID"
    login_as(@user)
    cleanup_test_uploaded_file
  end

  def teardown
    cleanup_test_uploaded_file
  end

  def test_index_successful
    get(:index)

    assert_response(:success)
    assert_template("index")

    assert_not_nil(assigns(:user))
    assert_not_nil(assigns(:movies))
    assert_not_nil(assigns(:recent_movies))
    assert_not_nil(assigns(:todays_movies))
    assert_not_nil(assigns(:calendar_movies))
    assert_not_nil(assigns(:calendar_year))
    assert_not_nil(assigns(:calendar_month))
  end

  def test_index_successful_not_logined
    logout
    get(:index)

    assert_response(:success)
    assert_template("index")
    assert_nil(assigns(:user))
    assert_nil(assigns(:movies))
    assert_not_nil(assigns(:recent_movies))
    assert_not_nil(assigns(:todays_movies))
    assert_not_nil(assigns(:calendar_movies))
    assert_not_nil(assigns(:calendar_year))
    assert_not_nil(assigns(:calendar_month))
  end

  # 新着ムービー表示
  def test_index_for_recent
    get(:index_for_recent)

    assert_response(:success)
    assert_template("index_for_recent")

    assert_not_nil(assigns(:movies))
  end

  # 新着ムービー表示
  def test_index_for_user
    get(:index_for_user, :user_id => @user.id)

    assert_response(:success)
    assert_template("index_for_user")

    assert_not_nil(assigns(:movies))
  end

  def test_show_successful
    movie = Movie.find(movies(:sns_tarou_public).id)
    get(:show, :id => movie.id)

    assert_response(:success)
    assert_template('show')

    assert_not_nil(assigns(:movie))
  end

  def test_show_successful_out_movie
    logout
    movie = Movie.find(movies(:sns_tarou_public_movie).id)
    get(:show, :id => movie.id)

    assert_response(:success)
    assert_template('show')

    assert_not_nil(assigns(:movie))
  end

  def test_show_failure_with_not_publicated_movie
    movie = Movie.find(movies(:sns_hanako_unpubliced).id)

    get(:show, :id => movie.id)

    assert_response(:redirect)
    assert_redirected_to(:action => 'failure_not_found')
  end

  def test_new_successful
    get(:new)

    assert_response(:success)
    assert_template("form")
    assert_not_nil(assigns(:user))
    assert_not_nil(assigns(:movie))
    assert(assigns(:movie).new_record?)
  end

  def test_new_with_temporary_file
    upload_temporary_file

    get(:new)

    assert_response(:success)
    assert_template('form')
    assert(!File.exists?(File.join(Movie::TEMPORARY_DATA_DIR,
                                   @request.session_options[:id] + '.wmv')))
  end

  def test_confirm_before_create_successful
    movie = Movie.plan

    uploaded_temp_file_path = 
      File.join(Movie::TEMPORARY_DATA_DIR,
                @request.session_options[:id] + '.wmv')

    post(:confirm_before_create, :movie => movie,
         :movie_file => uploaded_file(TEST_FILE_PATH, 'video/x-ms-wmv', 'sample.wmv'))

    assert_response(:success)
    assert_nil assigns(:invalid_movie_file)
    assert_nil assigns(:error_save)
    assert_template("confirm")
    assert_not_nil(assigns(:movie))
    assert_equal(movie[:title], assigns(:movie).title)
    assert_equal(movie[:body], assigns(:movie).body)
    assert_nil(assigns(:movie).start_date)
    assert_nil(assigns(:movie).end_date)
    assert_equal(movie[:visibility], assigns(:movie).visibility)
    assert(File.exists?(uploaded_temp_file_path))
    assert_not_nil(assigns(:movie_file))
  end

  def test_confirm_before_create_failure_contains_invalid_value
    movie = Movie.plan(:title => '', :body => '')

    uploaded_temp_file_path = 
      File.join(Movie::TEMPORARY_DATA_DIR,
                @request.session_options[:id] + '.wmv')

    post(:confirm_before_create, :movie => movie,
         :movie_file => uploaded_file(TEST_FILE_PATH, 'video/x-ms-wmv', 'sample.wmv'))

    assert_response(:success)
    assert_template("form")
    assert_not_nil(assigns(:movie))
    assert(assigns(:movie).errors.count > 0)
    assert(!File.exists?(uploaded_temp_file_path))
  end

  def test_confirm_before_create_failure_movie_file_not_attached
    movie = Movie.plan

    post(:confirm_before_create, :movie => movie, :movie_file => '')

    assert_response(:success)
    assert_template('form')
    assert_not_nil(assigns(:movie))
    assert(assigns(:error_movie_file_not_found))
  end

  def test_create_successful
    # 事前に別アクションで confirm_before_create アクションを叩いておく
    upload_temporary_file

    movie = Movie.plan

    movie_count = Movie.count
    my_movie_count = @user.movies(true).count

    post(:create, :movie => movie)

    assert_response(:redirect)
    assert_equal(movie_count + 1, Movie.count)
    assert_equal(my_movie_count + 1, @user.movies(true).count)
    @movie = Movie.find_by_title(movie[:title])
    assert_redirected_to(complete_after_create_movie_path(@movie))

    movie_file_path = Movie::ORIGINAL_DATA_DIR + '/' + @movie.id.to_s + '.wmv'
    assert(File.exists?(movie_file_path))
    assert_equal(@uploaded_file.size, File.size(movie_file_path))
    temporary_file_path = Movie::TEMPORARY_DATA_DIR + @request.session_options[:id] + '.wmv'
    assert(!File.exists?(temporary_file_path))
  end

  def test_create_cancel
    # 事前に別アクションで confirm_before_create アクションを叩いておく
    upload_temporary_file

    movie = Movie.plan

    post(:create, :movie => movie, "cancel" => "Cancel")

    assert_template("form")
  end

  def test_edit_successful
    movie = @user.movies.first
    get(:edit, :id => movie.id)

    assert_response(:success)
    assert_template('form')

    assert_not_nil(assigns(:user))
    assert_not_nil(assigns(:movie))
  end

  def test_edit_failure_with_another_users_movie
    movie = Movie.find_by_user_id(@another.id)
    get(:edit, :id => movie.id)

    assert_response(:redirect)
    assert_redirected_to(:action => 'failure_not_found')
  end

  def test_edit_failure_without_movie_id
    get(:edit)

    assert_response(:redirect)
    assert_redirected_to(:action => 'failure_not_found')
  end

  def test_confirm_before_update_successful
    movie_params = Movie.plan(:title => 'updated title', :body => 'updated comment')
    movie = Movie.find_by_user_id(@user.id)

    post(:confirm_before_update, :id => movie.id, :movie => movie_params)

    assert_response(:success)
    assert_template('confirm')
    assert_not_nil(assigns(:movie))
  end

  def test_confirm_before_update_failure_validation
    movie_params = Movie.plan(:title => '')
    movie = Movie.find_by_user_id(@user.id)

    post(:confirm_before_update, :id => movie.id, :movie => movie_params)

    assert_response(:success)
    assert_template('form')
    assert_not_nil(assigns(:movie))
    assert(!assigns(:movie).valid?)
  end

  def test_confirm_before_update_failure_with_another_users_movie
    movie_params = Movie.plan
    movie = Movie.find_by_user_id(@another.id)

    post(:confirm_before_update, :id => movie.id, :movie => movie_params)

    assert_response(:redirect)
    assert_redirected_to(:action => 'failure_not_found')
  end

  # 住所検索テスト（携帯用）
  def test_confirm_before_update_for_search_address_mobile
    set_mobile_user_agent
    movie_params = Movie.plan(:title => 'updated title', :body => 'updated comment')
    movie = Movie.find_by_user_id(@user.id)

    post(:confirm_before_update, :id => movie.id, :movie => movie_params,
         :search_address => "Search", :address => "NewYork")

    assert_template('form')
  end

  def test_update_successful
    movie_params = Movie.plan(
      :title => 'updated title',
      :body => 'updated comment'
    )
    movie = Movie.find_by_user_id(@user.id)

    put(:update, :id => movie.id, :movie => movie_params)

    assert_response(:redirect)
    @movie = Movie.find(movie.id)
    assert_redirected_to(complete_after_update_movie_path(@movie))
    assert_equal(movie_params[:title], @movie.title)
    assert_equal(movie_params[:body], @movie.body)
  end

  def test_update_cancel
    movie_params = Movie.plan
    movie = Movie.find_by_user_id(@user.id)

    put(:update, :id => movie.id, :movie => movie_params, :cancel => "cancel")

    assert_template("form")
  end

  def test_destroy_successful
    movie = Movie.find_by_user_id(@user.id)
    movie_count = Movie.count
    my_movie_count = @user.movies(true).count
    setup_movie_files(movie.id)

    delete(:destroy, :id => movie.id)

    assert_response(:redirect)
    assert_redirected_to(movies_path)
    assert_equal(movie_count - 1, Movie.count)
    assert_equal(my_movie_count - 1, @user.movies(true).count)
    assert(!Movie.exists?(movie.id))
    assert(!File.exists?(File.join(Movie::DATA_DIR, "#{movie.id}.flv")))
    assert(!File.exists?(File.join(Movie::DATA_DIR, "#{movie.id}.3gp")))
    assert(!File.exists?(File.join(Movie::DATA_DIR, "#{movie.id}.3g2")))
    assert(!File.exists?(File.join(Movie::ORIGINAL_DATA_DIR, "#{movie.id}.wmv")))
  end

  def test_destroy_failure_with_another_users_movie_id
    movie = Movie.find_by_user_id(@another.id)
    movie_count = Movie.count
    my_movie_count = @user.movies(true).count
    setup_movie_files(movie.id)

    delete(:destroy, :id => movie.id)

    assert_response(:redirect)
    assert_redirected_to(:action => 'failure_not_found')
    assert_equal(movie_count, Movie.count)
    assert_equal(my_movie_count, @user.movies(true).count)
    assert(Movie.exists?(movie.id))
    assert(File.exists?(File.join(Movie::DATA_DIR, "#{movie.id}.flv")))
    assert(File.exists?(File.join(Movie::DATA_DIR, "#{movie.id}.3gp")))
    assert(File.exists?(File.join(Movie::DATA_DIR, "#{movie.id}.3g2")))
    assert(File.exists?(File.join(Movie::ORIGINAL_DATA_DIR, "#{movie.id}.wmv")))
  end

  def test_search_with_blank_query
    query = ''
    
    get(:search, :query => query)

    assert_response(:success)
    assert_template('search')

    assert_not_nil(assigns(:movies))
    assert_kind_of(WillPaginate::Collection, assigns(:movies))
    assert_not_nil(assigns(:query_words))
    assert(assigns(:query_words).empty?)
    assert(!assigns(:movies).empty?)
  end
 
  def test_search_with_blank_query_not_logined
    logout
    query = ''
    
    get(:search, :query => query)

    assert_response(:success)
    assert_template('search')

    assert_not_nil(assigns(:movies))
    assert_kind_of(WillPaginate::Collection, assigns(:movies))
    assert_not_nil(assigns(:query_words))
    assert(assigns(:query_words).empty?)
    assert(!assigns(:movies).empty?)
  end

  def test_search_with_nil_query
    query = nil 
    
    get(:search, :query => query)

    assert_response(:success)
    assert_template('search')

    assert_not_nil(assigns(:movies))
    assert_kind_of(WillPaginate::Collection, assigns(:movies))
    assert_not_nil(assigns(:query_words))
    assert(assigns(:query_words).empty?)
    assert(!assigns(:movies).empty?)
  end

  def test_search_with_one_word_for_title
    query = '太郎の動画（外部公開）'

    get(:search, :query => query)

    assert_response(:success)
    assert_template('search')

    assert_not_nil(assigns(:movies))
    assert_kind_of(WillPaginate::Collection, assigns(:movies))
    assert_not_nil(assigns(:query_words))
    assert_equal(1, assigns(:query_words).size)
    assert(!assigns(:movies).empty?)
  end

  def test_ajax_update_recent_movies_successful_default
    xhr(:get, :update_recent_movies)

    assert_response(:success)
    assert_template('_recent_movies')

    assert_not_nil(assigns(:recent_movies))
  end

  def test_ajax_update_recent_movies_successful_default_without_login
    logout
    xhr(:get, :update_recent_movies)

    assert_response(:success)
    assert_template('_recent_movies')

    assert_not_nil(assigns(:recent_movies))
  end

  def test_ajax_update_recent_movies_successful_default_other_page
    xhr(:get, :update_recent_movies, :page => 2)

    assert_response(:success)
    assert_template('_recent_movies')

    assert_not_nil(assigns(:recent_movies))
  end

  def test_ajax_update_my_movies_successful_default
    xhr(:get, :update_my_movies)

    assert_response(:success)
    assert_template('_movies')

    assert_not_nil(assigns(:movies))
  end

  def test_ajax_update_my_movies_successful_default_other_page
    xhr(:get, :update_my_movies, :page => 2)

    assert_response(:success)
    assert_template('_movies')

    assert_not_nil(assigns(:movies))
  end

  def test_thumbnail
    movie = Movie.find(:first)
    get(:thumbnail, :id => movie.id)

    assert_response(:success)
  end

  def test_thumbnail_without_login
    logout
    movie = Movie.find(movies(:sns_tarou_public_movie).id)
    get(:thumbnail, :id => movie.id)

    assert_response(:success)
  end

  def test_map
    get(:map)

    assert_response(:success)
    assert_template('map')

    assert_not_nil(assigns(:movies))
  end

  def test_map_without_login
    logout
    get(:map)

    assert_response(:success)
    assert_template('map')

    assert_not_nil(assigns(:movies))
  end

  # 携帯用ムービーマップ表示
  def test_map_for_mobile
    Movie.make(:latitude => 200, :longitude => 500)
    get(:map_for_mobile, :latitude => 1, :longitude => 300, :span_lat => 250, :span_lng => 250)

    assert_response(:success)
    assert_template('map_for_mobile')

    assert_not_nil(assigns(:records))
  end

  # 携帯用ムービーマップ表示
  def test_map_for_mobile_without_login
    logout
    Movie.make(:latitude => 200, :longitude => 500)
    get(:map_for_mobile, :latitude => 200, :longitude => 450, :span_lat => 250, :span_lng => 250)

    assert_response(:success)
    assert_template('map_for_mobile')

    assert_equal false, assigns(:records).empty?
  end

  private
  def cleanup_test_uploaded_file
    Dir.glob(Movie::ORIGINAL_DATA_DIR + '/*') do |f|
      File.delete(f) if File.file?(f)
    end
    Dir.glob(Movie::TEMPORARY_DATA_DIR + '/*') do |f|
      File.delete(f) if File.file?(f)
    end
    Dir.glob(Movie::DATA_DIR + '/*') do |f|
      File.delete(f) if File.file?(f)
    end
  end

  def upload_temporary_file
    movie = Movie.plan

    uploaded_temp_file_path = 
      File.join(Movie::TEMPORARY_DATA_DIR,
                @request.session_options[:id] + '.wmv')
    @uploaded_file = uploaded_file(TEST_FILE_PATH, 'video/x-ms-wmv', 'sample.wmv')

    post(:confirm_before_create, :movie => movie,
         :movie_file => @uploaded_file)
  end

  def setup_movie_files(movie_id)
    FileUtils.copy(TEST_FILE_PATH,
                   File.join(Movie::DATA_DIR, "#{movie_id}.flv"))
    FileUtils.copy(TEST_FILE_PATH,
                   File.join(Movie::DATA_DIR, "#{movie_id}.3gp"))
    FileUtils.copy(TEST_FILE_PATH,
                   File.join(Movie::DATA_DIR, "#{movie_id}.3g2"))
    FileUtils.copy(TEST_FILE_PATH,
                   File.join(Movie::ORIGINAL_DATA_DIR, "#{movie_id}.wmv"))
  end
end
