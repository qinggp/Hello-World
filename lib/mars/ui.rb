class Mars::UI
  include Singleton


  attr_accessor :preferences, :mobile_preference_sequences,
                :preference_sequences, :my_contents_sequences,
                :my_contents, :portal_contents_sequences, :portal_contents

  def initialize
    super

    # PC用
    define_element_set :main_menus, Mars::UI::Part
    define_element_set :main_search_buttons, Mars::UI::Part
    define_element_set :profile_contents, Mars::UI::Part
    define_element_set :navigations, Mars::UI::Part
    define_element_set :my_menus, Mars::UI::Part
    define_element_set :friend_menus, Mars::UI::Part
    define_element_set :admin_sns_extension_configs, Mars::UI::Part
    define_element_set :portal_navigations, Mars::UI::Part

    # 携帯用
    define_element_set :mobile_main_menus, Mars::UI::Link
    define_element_set :mobile_my_home_contents, Mars::UI::Part
    define_element_set :mobile_my_home_contents_navigations, Mars::UI::Link
    define_element_set :mobile_search_links, Mars::UI::Link
    define_element_set :mobile_footers, Mars::UI::Part
    define_element_set :mobile_profile_menus, Mars::UI::Part
    define_element_set :mobile_profile_contents, Mars::UI::Part
    define_element_set :mobile_portal_menus, Mars::UI::Link
    define_element_set :mobile_portal_news, Mars::UI::Part
    define_element_set :mobile_portal_news_navigations, Mars::UI::Inline

    @preference_sequences = []
    @mobile_preference_sequences = []
    @preferences = {}

    @my_contents_sequences = []
    @my_contents = {}

    @portal_contents_sequences = []
    @portal_contents = {}
  end

  # 個人設定用情報を初期化
  #
  # ==== 引数
  #
  # * categories - カテゴリ名の配列
  def init_preferences(*categories)
    @preference_sequences = categories
    @preference_sequences.each do |name|
      @preferences[name] = Mars::UI::ElementSet.new("preferences_#{name}", Mars::UI::Part)
    end
  end

  # トップページのメニューを初期化
  #
  # ==== 引数
  #
  # * categories - カテゴリ名の配列
  def init_my_contents(*categories)
    @my_contents_sequences = categories
    @my_contents_sequences.each do |name|
      @my_contents[name] = Mars::UI::ElementSet.new("my_contents_#{name}", Mars::UI::Part)
    end
  end

  # ポータルページのメニューを初期化
  #
  # ==== 引数
  #
  # * categories - カテゴリ名の配列
  def init_portal_contents(*categories)
    @portal_contents_sequences = categories
    @portal_contents_sequences.each do |name|
      @portal_contents[name] = Mars::UI::ElementSet.new("portal_contents_#{name}", Mars::UI::Part)
    end
  end

  # UIに紐付くElementSetの初期化
  def clear
    clear_defined_element_sets!
    @preferences.values.map(&:clear)
    @my_contents.values.map(&:clear)
    @portal_contents.values.map(&:clear)
  end

  autoload :ElementSet, File.join(File.dirname(__FILE__), "/ui/element_set")
  autoload :Element, File.join(File.dirname(__FILE__), "/ui/element")
  autoload :Part, File.join(File.dirname(__FILE__), "/ui/part")
  autoload :Link, File.join(File.dirname(__FILE__), "/ui/link")
  autoload :Inline, File.join(File.dirname(__FILE__), "/ui/inline")


  private

  # UIの要素セットの定義
  def define_element_set(element_set_id, default_element_class)
    element_set_id = element_set_id.to_s
    @defined_element_set_ids ||= []
    @defined_element_set_ids << element_set_id
    self.class.class_eval <<-CODE
      attr_accessor :#{element_set_id}
    CODE
    instance_variable_set("@#{element_set_id}", Mars::UI::ElementSet.new(element_set_id, default_element_class))
  end

  # UIの要素セット内部をクリア
  def clear_defined_element_sets!
    @defined_element_set_ids.each{|id| self.instance_variable_get("@#{id}").clear }
  end
end
