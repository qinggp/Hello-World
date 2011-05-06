require File.dirname(__FILE__) + '/../test_helper'

class MovieTest < ActiveSupport::TestCase
  # テスト用アップロードファイルパス
  TEST_FILE_PATH = File.join(RAILS_ROOT, 'public', 'images', 'rails.png')

  def setup
    @taro = users(:sns_tarou)
    @hanako = users(:sns_hanako)
  end

  def test_recents
    user = @taro
    @movies = Movie.recents(user.id)
    assert_not_nil(@movies)
    assert_kind_of(Array, @movies)
    assert(!@movies.collect {|m| m.id}.include?(movies(:convert_yet).id))
    assert(@movies.collect {|m| m.id}.include?(movies(:sns_zirou_friend).id))
  end

  def test_recents_paginate_for_out
    @movies = Movie.recents_paginate(nil, { :page => 1, :per_page => 5 })

    assert_not_nil(@movies)
    assert_kind_of(Array, @movies)
    assert(@movies.size > 0)
    @movies.each do |movie| assert(movie.visibility == MoviePreference::VISIBILITIES[:publiced]) end
  end

  def test_recents_for_map
    @movies = Movie.recents_for_map(@taro.id)
    assert_not_nil(@movies)
    @movies.each do |movie|
      assert(!movie.latitude.blank?)
      assert(!movie.longitude.blank?)
      assert(!movie.zoom.blank?)
    end
  end

  def test_convert_status_when_new
    movie = Movie.new(Movie.plan(:convert_status => "",
                                 :start_date => Date.today.to_s(:db)))
    assert(movie.save)
    assert_not_nil(movie.convert_status)
    assert_equal(0, movie.convert_status)
  end

  def test_save_with_start_and_end_date_sameday
    movie = Movie.new(Movie.plan(:start_date => '2008/01/01', :end_date => '2008/01/01'))
    assert(movie.save)
  end

  def test_save_with_start_and_end_date_invalid
    movie = Movie.new(Movie.plan(:start_date => '2008/01/02',
                                 :end_date => '2008/01/01'))
    assert(!movie.save)
    assert(movie.errors.count > 0)
    assert(movie.errors.invalid?(:start_date))
  end

  def test_save_with_end_date_only
    movie = Movie.new(Movie.plan(:start_date => '',
                                 :end_date => '2008/01/01'))
    assert(!movie.save)
    assert(movie.errors.count > 0)
    assert(movie.errors.invalid?(:end_date))
  end

  def test_search_no_words
    @movies = Movie.search([], @taro.id)
    assert_not_nil(@movies)
    assert(@movies.empty?)
  end

  def test_search_with_one_word_for_title
    words = %w(太郎の動画（外部公開)
    @movies = Movie.search(words, @taro.id)
    assert_not_nil(@movies)
    assert(!@movies.empty?)
    assert_equal(1, @movies.size)
    assert(@movies.collect {|m| m.id}.include?(movies(:sns_tarou_public).id))
  end

  def test_search_with_one_word_for_body
    words = %w(花子の動画（外部公開）本文)
    @movies = Movie.search(words, @taro.id)
    assert_not_nil(@movies)
    assert(!@movies.empty?)
    assert_equal(1, @movies.size)
    assert(@movies.collect {|m| m.id}.include?(movies(:sns_hanako_public).id))
  end

  def test_search_with_one_word_for_title_and_body
    words = %w(検索用)
    @movies = Movie.search(words, @taro.id)
    assert_not_nil(@movies)
    assert(!@movies.empty?)
    assert_equal(2, @movies.size)
    assert(@movies.collect {|m| m.id}.include?(movies(:search_sns_hanako_public).id))
    assert(@movies.collect {|m| m.id}.include?(movies(:search_sns_tarou_member).id))
  end

  def test_search_with_multi_word_for_title_and_body
    words = %w(複数検索ワード 検索複数ワード)
    @movies = Movie.search(words, @taro.id)
    assert_not_nil(@movies)
    assert(!@movies.empty?)
    assert_equal(2, @movies.size)
    assert(@movies.collect {|m| m.id}.include?(movies(:multi_search_sns_hanako_public).id))
    assert(@movies.collect {|m| m.id}.include?(movies(:multi_search_sns_tarou_member).id))
  end

  def test_search_with_friend_movie_title
    words = %w(次郎の動画)
    @movies = Movie.search(words, @taro.id)
    assert_not_nil(@movies)
    assert(!@movies.empty?)
    assert(@movies.collect {|m| m.id}.include?(movies(:sns_zirou_friend).id))
  end

  def test_search_with_not_friend_movie_title
    words = %w(次郎の動画)
    @movies = Movie.search(words, @hanako.id)
    assert_not_nil(@movies)
    assert(@movies.empty?)
  end

  def test_todays
    @movies = Movie.todays(@taro.id)
    assert_not_nil(@movies)
    today = Date.today
    @movies.each do |m|
      if !m.start_date.blank?
        if !m.end_date.blank?
          assert(m.start_date <= today)
          assert(m.end_date >= today)
        else
          assert_equal(today, m.start_date)
        end
      end
    end
  end

  def test_find_publication_successful
    assert_not_nil(Movie.find_publication(@taro.id, movies(:sns_hanako_public).id))
    assert_nil(Movie.find_publication(@taro.id, movies(:convert_yet).id))
    assert_nil(Movie.find_publication(@taro.id, movies(:sns_hanako_unpubliced).id))
    assert_not_nil(Movie.find_publication(nil, movies(:sns_tarou_public).id))
  end

  def test_save_start_date_only
    movie = Movie.new(Movie.plan(
                      :visibility => MoviePreference::VISIBILITIES[:member_only],
                      :start_date => Date.today))
    assert(movie.save)
    assert_not_nil(movie.start_date)
    assert_not_nil(movie.end_date)
    assert_equal(movie.start_date, movie.end_date)
  end

  # 動画変換テスト
  #
  # NOTE: 失敗した場合は log/convert.log を参照してください
  # 動画変換ライブラリの導入方法はREADMEを参照してください
  def test_convert
    %w(mp3 3gp).each do |ext|
      upload_file = File.join(File.dirname(__FILE__), "../fixtures/movie/video.#{ext}")

      movie = Movie.make(:convert_status => Movie::CONVERT_STATUSES[:yet])
      FileUtils.cp(upload_file, File.join(Movie::ORIGINAL_DATA_DIR, "#{movie.id}.#{ext}"))
      Movie.convert!(movie.id)

      assert_equal true, File.exists?(File.join(Movie::DATA_DIR, "#{movie.id}.3gp"))
      assert_equal true, File.exists?(File.join(Movie::DATA_DIR, "#{movie.id}.flv"))
      assert_equal true, File.exists?(File.join(Movie::DATA_DIR, "#{movie.id}.3g2"))
      movie.remove_movie_files
    end
  end

  def test_file_size
    movie = Movie.make
    setup_movie_files(movie.id)

    assert_not_nil movie.file_size("3gp")
    movie.remove_movie_files
  end

  # ユーザ削除時の動画削除チェック
  def test_destroy_related_to_user_record
    user = User.make
    movie_count = Movie.count
    3.times do
      Movie.make(:user_id => user.id)
    end
    3.times do
      Movie.make
    end
    assert_equal movie_count + 6, Movie.count
    user.destroy
    assert_equal movie_count + 3, Movie.count
  end

  private
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
