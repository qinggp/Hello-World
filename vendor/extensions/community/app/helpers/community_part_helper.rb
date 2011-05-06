# コミュニティ機能UI拡張ヘルパ
#
# community_extension.rb で ui に部分テンプレートを追加する際、
# 何も指定しなければこのヘルパモジュールを利用します。
#
# NOTE: 名前衝突の恐れがあるため「community_」をメソッド名先頭に
# 付けてください。
module CommunityPartHelper
  # コミュニティの画像へのパスを返す
  #
  # ==== 引数
  #
  # * options
  # * <tt>:image_type</tt> - 画像のタイプ（default :medium）
  # * <tt>:width</tt> - 横幅
  # * <tt>:height</tt> - 縦幅
  # * <tt>:admin</tt> - コミュニティの管理人であるかどうか
  def community_display_image(community, options={})
    html = ""
    html << theme_image_tag("community/comm_owner.gif") if options[:admin]

    options[:image_type] ||= :medium

    if community.image
      image_path = show_unpublic_image_community_path(:community_id => community.id,
                                                      :id => community.id,
                                                      :image_type => options[:image_type])
    else
      image_path = "noimage.gif"
    end

    html << theme_image_tag(image_path, :width => options[:width], :height => options[:height])
  end
end
