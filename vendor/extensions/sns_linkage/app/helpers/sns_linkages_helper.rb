module SnsLinkagesHelper
  # SNS連携URL生成
  def sns_link_url(key)
    unless key.blank?
      return url_for(:controller => :sns_linkage_api, :action => :show, :key => key, :only_path => false, :protocol => "http://")
    end
  end

  # SNS連携データをカテゴリでグルーピング
  def sns_link_data_groups_by_category(items)
    res = {}
    items.each do |i|
      res[i.category.content.to_s] ||= []
      res[i.category.content.to_s] << i
    end
    return res
  end
end
