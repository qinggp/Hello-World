# コミュニティのカテゴリを管理
class Admin::CommunityCategoriesController < Admin::ApplicationController

  # 昇順降順を表す定数
  ASC = 1
  DESC = 2

  # ソート対象を表す定数
  NAME = 1
  COMMUNITY_NAME = 2
  USER_NAME = 3


  with_options :redirect_to => :admin_community_categories_url do |con|
    con.verify :params => "id", :only => %w(edit confirm_before_update
      sub_category_list sub_category_edit
      map_category_edit  )
    con.verify :params => "community_category", 
      :only => %w(confirm_before_create create confirm_before_update update)
    con.verify :params => "community_map_category",
      :only => %w(map_category_confirm_before_update map_category_update)
    con.verify :method => :post, :only => %w(confirm_before_create confirm_before_update create)
    con.verify :method => :put, :only => %w(update map_category_update)
  end

  

  # 一覧の表示と並び替え，レコードの検索．
  def index
    if params[:per_page] && params[:per_page].to_i == 0
      @paginated = false
    else
      @paginated = true
    end
    order = construct_order_by_query
    if @paginated
      @community_categories =
        CommunityCategory.paginate(:conditions => ['parent_id is null '],
                                   :per_page => (params[:per_page] ? params[:per_page] : 5),
                                   :page => params[:page],
                                   :order => order)
    else
      @community_categories = CommunityCategory.find(:all,:conditions => ['parent_id is null'], :order => order)
    end
  end

  # サブカテゴリの一覧
  def sub_category_list
    if params[:per_page] && params[:per_page].to_i == 0
      @paginated = false
    else
      @paginated = true
    end
    order = construct_order_by_query
    @find_id = params[:id]
    if @paginated
      @community_categories =
        CommunityCategory.paginate(:conditions => ['parent_id = ?', @find_id],
                                   :per_page => (params[:per_page] ? params[:per_page] : 5),
                                   :page => params[:page],
                                   :order => order)
    else
      @community_categories = CommunityCategory.find(:all,:conditions => ['parent_id = ?', @find_id], :order => order)
    end
  end

  # マップカテゴリ一覧
  def map_category_list
    if params[:per_page] && params[:per_page].to_i == 0
      @paginated = false
    else
      @paginated = true
    end
    order = construct_order_by_query

    if @paginated
      query = {:per_page => (params[:per_page] ? params[:per_page] : 5),
               :page => params[:page],
               :order => order
              }
      if params[:order] && params[:order][:kind]
        case params[:order][:kind].to_i
        when USER_NAME
          query.merge!(:include => "author")
        when COMMUNITY_NAME
          query.merge!(:include => "community")
        end
      end
      @community_map_categories =
        CommunityMapCategory.paginate(query)

    else
      @community_map_categories = CommunityMapCategory.find(:all, :order => order)
    end
  end

  def new
    @community_category ||= CommunityCategory.new

    render "form"
  end

  # サブカテゴリ登録フォームの表示
  def sub_category_new
    @category_state_id = "0"
    if params[:category_state_id]
      @category_state_id = params[:category_state_id] if params[:category_state_id]
      @community_category ||= CommunityCategory.new(:parent_id => params[:category_state_id])
      @selected_category = CommunityCategory.find(params[:category_state_id])
    else
      @community_category ||= CommunityCategory.new
    end
    render "form"
  end

  # 編集フォームの表示．
  def edit
    @community_category ||= CommunityCategory.find(params[:id])
    render "form"
  end

 # サブカテゴリ編集フォームの表示
  def sub_category_edit
    @category_state_id = "0"
    @community_category ||= CommunityCategory.find(params[:id])
    render "form"
  end

  # マップカテゴリ編集フォームの表示
  def map_category_edit
    @community_map_category ||= CommunityMapCategory.find(params[:id])
    render "form"
  end

  # 登録確認画面表示
  def confirm_before_create
    @community_category = CommunityCategory.new(params[:community_category])
    @parent_category ||= CommunityCategory.find(@community_category.parent_id) if @community_category.parent_id
    @category_state_id = params[:category_state_id] if params[:category_state_id]
    @selected_category = CommunityCategory.find(@category_state_id) if @category_state_id && @category_state_id != "0"

    if params[:clear]
      @community_category.name = ""
      return render "form"
    end

    if @community_category.valid?
      render "confirm"
    else
      render "form"
    end
  end

  # 編集確認画面表示
  def confirm_before_update
    @community_category = CommunityCategory.find(params[:id])
    @community_category.attributes = params[:community_category]
    @parent_category ||= CommunityCategory.find(@community_category.parent_id) if @community_category.parent_id
    @category_state_id = params[:category_state_id] if params[:category_state_id]

    if params[:clear]
      @community_category.name = ""
      return render "form"
    end
    if @community_category.valid?
      render "confirm"
    else
      render "form"
    end
  end

  # マップカテゴリ編集確認画面
  def map_category_confirm_before_update
    @community_map_category = CommunityMapCategory.find(params[:id])
    @community_map_category.attributes = params[:community_map_category]
    return redirect_to map_category_edit_admin_community_category_path(@community_map_category) if params[:clear]

    if @community_map_category.valid?
      render "confirm"
    else
      render "form"
    end
  end

  # 登録データをDBに保存．
  def create
    @community_category = CommunityCategory.new(params[:community_category])
    @parent_category ||= CommunityCategory.find(@community_category.parent_id) if @community_category.parent_id
    @category_state_id = params[:category_state_id] if params[:category_state_id]
    @selected_category = CommunityCategory.find(@category_state_id) if @category_state_id && @category_state_id != "0"
    return render "form" if params[:cancel] || !@community_category.valid?

    CommunityCategory.transaction do
      @community_category.save!
    end

    redirect_to complete_after_create_admin_community_category_path(@community_category)
  end

  # コミュニティカテゴリ更新データをDBに保存．
  def update
    @community_category = CommunityCategory.find(params[:id])
    @community_category.attributes = params[:community_category]

    @parent_category ||= CommunityCategory.find(@community_category.parent_id) if @community_category.parent_id
    @category_state_id = params[:category_state_id] if params[:category_state_id]
    @selected_category = CommunityCategory.find(@category_state_id) if @category_state_id && @category_state_id != "0"
    return render "form" if params[:cancel] || !@community_category.valid?

    CommunityCategory.transaction do
      @community_category.save!
    end

    redirect_to complete_after_update_admin_community_category_path(@community_category)
  end

  # マップカテゴリ更新データをDBに保存
  def map_category_update
    @community_map_category = CommunityMapCategory.find(params[:id])
    @community_map_category.attributes = params[:community_map_category]
    
    return render "form" if params[:cancel] || !@community_map_category.valid?

    CommunityMapCategory.transaction do
      @community_map_category.save!
    end

    redirect_to complete_after_update_admin_community_category_path(@community_map_category)
  end


  private

  #クエリのorder句の生成
  def construct_order_by_query
    order_by_query = "name"
    
    if params[:order] && params[:order][:kind]
      case params[:order][:kind].to_i
      when NAME
       order_by_query = "name"
      when USER_NAME
       order_by_query = "users.name"
      when COMMUNITY_NAME
       order_by_query = "communities.name"
      else
       order_by_query = "name"
      end
    else
      order_by_query = "name"
    end


    if params[:order] && params[:order][:asc_or_desc]
      if params[:order][:asc_or_desc].to_i == DESC
        order_by_query << " desc "
      end
    end

    order_by_query
  end

  
end
