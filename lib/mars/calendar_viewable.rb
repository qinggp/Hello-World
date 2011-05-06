# カレンダ表示
#
# カレンダ表示対象のコントローラにincludeしてください。
module Mars::CalendarViewable
  def self.included(klass)
    klass.class_eval do
      helper Mars::CalendarViewable::CalendarHelper
    end
    klass.send(:include, InstanceMethods)
  end

  module InstanceMethods
    # カレンダー表示
    def show_calendar
      @calendar_year, @calendar_month = Date.today.year, Date.today.month
      unless params[:date].blank?
        @calendar_year = params[:date][:year].to_i unless params[:date][:year].blank?
        @calendar_month = params[:date][:month].to_i unless params[:date][:month].blank?
      end
      set_calendar_params
      respond_to do |format|
        format.html
        format.js {render :partial => params[:partial]}
      end
    end

    private

    # カレンダー表示に必要なパラメータ設定
    def set_calendar_params
      raise NotImplementedError
    end
  end

  module CalendarHelper

    # Mars用カレンダーHTML出力
    def mars_calendar(opts, &block)
      block ||= Proc.new {|d| nil}
      html =
        calendar(opts) do |cur|
          cell_text, cell_attrs = block.call(cur)
          cell_text  ||= cur.mday
          cell_attrs ||= {:class => "day"}
          cell_attrs[:class] += " saturday" if [6].include?(cur.wday)
          cell_attrs[:class] += " sunday" if [0].include?(cur.wday)
          [cell_text, cell_attrs]
        end
      # NOTE: 見出しのX月を削除するため
      html.sub(/<tr><th colspan="7" class="\w+">\w+<\/th><\/tr>/, "")
    end

    # 見出し表示
    def display_calender_month(options)
      @calendar_year ||= Date.today.year
      @calendar_month ||= Date.today.month
      l(Date.new(@calendar_year, @calendar_month), options)
    end

    # 日付選択セレクトボックス出力（JS）
    def calendar_selects_remote(opts)
      partial = opts[:partial] ? opts[:partial] : opts[:update]
      url = opts[:url].merge(:partial => partial)
      @calendar_year ||= Date.today.year
      @calendar_month ||= Date.today.month

      form_remote_tag(:update => opts[:update],
                      :url => url,
                      :html => { :style => 'margin:0px;'}) do
        html = "#{select_year(@calendar_year || Date.today)}年"
        html << "#{select_month(@calendar_month || Date.today, :use_month_numbers => true)}月"
        html << submit_tag('表示')
      end
      return ""
    end

    # 月移動リンク出力（JS）
    def calendar_move_remote(opts)
      partial = opts[:partial] ? opts[:partial] : opts[:update]
      url = opts[:url].merge(:partial => partial)
      @calendar_year ||= Date.today.year
      @calendar_month ||= Date.today.month

      prev_url =
        url.merge(:date => {
                    :year => (Date.new(@calendar_year, @calendar_month, 1) << 1).year,
                    :month => (Date.new(@calendar_year, @calendar_month, 1) << 1).month})
      now_url =
        url.merge(:date => { :year => Date.today.year,
                    :month => Date.today.month })
      next_url =
        url.merge(:date => { :year => (Date.new(@calendar_year, @calendar_month, 1) >> 1).year,
                    :month => (Date.new(@calendar_year, @calendar_month, 1) >> 1).month })

      html = link_to_remote('＜＜',
                            {:update => opts[:update],
                              :url => prev_url},
                            :style => 'text-decoration:none;')
      html << link_to_remote(' ■ ',
                             {:update => opts[:update],
                               :url => now_url},
                             :style => 'text-decoration:none;')
      html << link_to_remote('＞＞',
                             {:update => opts[:update],
                               :url => next_url},
                             :style => 'text-decoration:none;')
    end

    # 月移動リンク出力
    #
    # ==== 引数
    #
    # * block - URL生成処理
    def calendar_move_to(&block)
      @calendar_year ||= Date.today.year
      @calendar_month ||= Date.today.month

      prev_url =
        block.call(:date => {
                     :year => (Date.new(@calendar_year, @calendar_month, 1) << 1).year,
                     :month => (Date.new(@calendar_year, @calendar_month, 1) << 1).month})
      now_url =
        block.call(:date => {
                     :year => Date.today.year,
                     :month => Date.today.month })
      next_url =
        block.call(:date => {
                     :year => (Date.new(@calendar_year, @calendar_month, 1) >> 1).year,
                     :month => (Date.new(@calendar_year, @calendar_month, 1) >> 1).month })

      html = link_to('＜＜', prev_url, :style => 'text-decoration:none;')
      html << link_to('■', now_url, :style => 'text-decoration:none;')
      html << link_to('＞＞', next_url, :style => 'text-decoration:none;')
    end

    # 携帯用カレンダー表示
    # 月ごとに表示する
    # 表示する情報がある日付のみ、その情報を出力する
    #
    # ==== 引数
    # * options
    # * <tt>:date_url</tt> - 日付へのリンクオプション
    def mars_calendar_mobile(options ={ }, &block)
      html = ""
      start_month = Date.civil(@calendar_year, @calendar_month)
      (start_month..start_month.end_of_month).each do |cur|
        items =  block.call(cur)
        unless items.blank?
          date_str = cur.day.to_s + "日"
          unless options[:date_url].blank?
            date_str = link_to(date_str,
                               options[:date_url].merge(:date => cur))
          end
          items.unshift("[" + date_str + "]")
          items << %Q(<hr size="1" noshade>)
          html << items.join("<br />")
        end
      end
      html = "今月はありません" if html.blank?
      html
    end
  end
end
