# UIインラインテンプレート
#
# 初期化時に渡すオプションについて
# * :inline インラインテンプレートの文字列。
class Mars::UI::Inline < Mars::UI::Element
  attr_reader :inline

  # 初期化
  #
  # ==== 引数
  #
  # * name
  # * options - :inline
  def initialize(name, options = {})
    super
    check_requirement_options(:inline)
    @inline = options[:inline]
  end

  private
  # インラインテンプレートレンダリング
  def display_template(view, options={})
    view.render :inline => @inline
  end
end
