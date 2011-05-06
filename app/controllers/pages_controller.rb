# 静的ページ管理
class PagesController < ApplicationController

  # レコードの詳細情報の表示．
  def show
    @page = Page.find_by_page_id(params[:id])
    @title = @page.title
  end
end
