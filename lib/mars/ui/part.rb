# UI部分テンプレート
#
# 初期化時に渡すオプションについて
# * :partial 部分テンプレートのパス。指定しない場合はデフォルト値が入る(@@default_part_dirname + name)
# * :helper ヘルパ名
# * :extension 拡張機能インスタンス。:helperが指定されない時に拡張機能名からデフォルトのヘルパを設定する
class Mars::UI::Part < Mars::UI::Element
  attr_reader :partial, :helper, :extension

  @@default_part_dirname = "/part"

  # 初期化
  #
  # ==== 引数
  #
  # * name
  # * options - :partial, :helper, :extension
  def initialize(name, options = {})
    super
    @partial = options[:partial] || File.join(@@default_part_dirname, @element_set_id, name.to_s)
    @helper = options[:helper]
    @extension = options[:extension]
    @helper ||= @extension.nil? ? nil : "#{@extension.extension_name.to_s}PartHelper"
  end

  # 標準の部分テンプレート格納ディレクトリ返却
  def default_part_dirname
    @@default_part_dirname
  end

  private

  # 表示
  # 
  # ==== 引数
  #
  # * view - ActionView
  # * options - render に渡すオプション
  #
  # ==== 戻り値
  #
  # render 結果のHTML
  def display_template(view, options={})
    if @helper
      helper_class = @helper.to_s.camelize.constantize rescue nil
    end
    if @extension
      helper_class = "#{@extension.extension_name.to_s}PartHelper".constantize rescue nil
    end
    view.helpers.send(:include, helper_class) if helper_class
    return view.render({:partial => @partial}.merge(options))
  end
end
