# コミュニティカテゴリ管理ヘルパ
module Admin::CommunityCategoriesHelper

   # 登録／更新画面のFrom情報生成
  def form_params
    if @community_category || @community_map_category
      if @community_category
        if @community_category.new_record?
          {:url => confirm_before_create_admin_community_categories_path,
            :model_instance => @community_category, :multipart => true
            }
        else
          {:url => confirm_before_update_admin_community_categories_path(:id => @community_category.id),
            :model_instance => @community_category, :multipart => true

            }
        end
      elsif @community_map_category
          {:url => map_category_confirm_before_update_admin_community_categories_path(:id => @community_map_category.id),
            :model_instance => @community_map_category, :multipart => true

            }
      end
    end
  end


  def confirm_form_params
    if @community_category
      if @community_category.new_record?
        {:url => admin_community_categories_path, :method => :post,
          :model_instance => @community_category}
      else
        {:url => admin_community_category_path(@community_category), :method => :put,
          :model_instance => @community_category}
      end
    elsif @community_map_category
        {:url => map_category_update_admin_community_category_path(@community_map_category), :method => :put,
          :model_instance => @community_map_category

          }
    end
  end

  # コミュニティカテゴリをソートするためのリンクパラメータの生成
  # kind: ソート対象を表す数字
  def parameter_for_order_link(kind)
    figure = ""
    asc_or_desc = Admin::CommunityCategoriesController::DESC

    if params[:order] && params[:order][:kind].to_i == kind
      # 現在のソート対象と一致しているとき
      case params[:order][:asc_or_desc].to_i
      when Admin::CommunityCategoriesController::ASC
        figure =  "▲"
        asc_or_desc = Admin::CommunityCategoriesController::DESC
      when Admin::CommunityCategoriesController::DESC
        figure = "▼"
        asc_or_desc = Admin::CommunityCategoriesController::ASC
      else
        figure = "▼"
        asc_or_desc = Admin::CommunityCategoriesController::ASC
      end
    elsif !params[:order] && kind.to_i == Admin::CommunityCategoriesController::NAME
      # デフォルトのソート
      figure = "▼"
    end

    order_parameter = {:order => {:kind => kind, :asc_or_desc => asc_or_desc}}

    yield(order_parameter) if block_given?
    concat figure unless figure.blank?
  end

  # 親カテゴリのセレクトメニュー
  def options_for_select_with_parent_categories(community_category_id)
    categories = CommunityCategory.root
    list = categories.map do |category|
      [category.name_with_parent, category.id]
    end

    options_for_select(list, community_category_id.to_i)
  end

  def find_parent_category_name(parent_id)
    parent_category = CommunityCategory.find(:first, :conditions => ['id = ?',parent_id])
    return parent_category.name
  end

end