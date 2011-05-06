module RankingsHelper

  # 各ランキングを表示する
  #
  # ==== 引数
  # * rank: ランキングの順位
  # * link: 表示されるリンク先
  # * count: ランキング対象となったカウント数（トモダチの数など）
  # * link_in_image: 一位の場合、画像とリンクが表示されるので、それ用
  def display_ranking(rank, link, count, link_in_image)
    return if count.to_i <= 0
    if rank == 1
      first_ranking(link_in_image, link, count)
    else
      normal_ranking(rank, link, count)
    end
  end

  private

  def normal_ranking(rank, link, count)
    content_tag(:div, :class => "ranking_list") do
      ranking_text(rank, link, count)
    end
  end

  def first_ranking(link_in_image, link, count)
    content_tag(:div, :align => "center", :style => "height: 180px;") do
      html = ""
      html << content_tag(:div, :style => "margin-top: 5px;") do
        image = ""
        image << content_tag(:div) do
          theme_image_tag("ranking/rank_first.png", :size => "30x12")
        end
        image << link_in_image
      end

      html << content_tag(:div, :style => "padding: 2px; text-align: center;") do
        ranking_text(1, link, count)
      end
    end
  end

  def ranking_text(rank, link, count)
    "No.#{rank} #{link} (#{count})"
  end
end
