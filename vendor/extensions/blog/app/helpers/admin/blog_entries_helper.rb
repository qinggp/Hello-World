# ブログ管理ヘルパ
module Admin::BlogEntriesHelper

  include BlogCommentsHelper
  include Mars::Blog::EntryBodyViewHelper
  include BlogCategoriesViewHelper
  include Admin::ContentsHelper

  # ブログの書き込みに対する添付の表示
  def display_write_attachment(entry)
    html = ""
    entry.blog_attachments.each do |attachment|
        html << display_attachment_file(attachment,
                 :attachment_path => show_unpublic_image_blog_entry_path(entry,
                                       :blog_attachment_id => attachment.id,
                                       :image_type => "medium"),
                 :original_attachment_path => show_unpublic_image_blog_entry_path(entry,
                                       :blog_attachment_id => attachment.id)
        )
    end
    return html
  end

  # ファイル一覧の添付の表示
  # ==== 引数
  # * attachment
  def display_attachment(attachment)
    html = ""
    case attachment.class.to_s
    when 'BlogAttachment'
      option = {:blog_attachment_id => attachment.id}
      attachment_path = Proc.new{show_unpublic_image_blog_entry_path(attachment.blog_entry_id, option.merge(:image_type => "thumb"))}
      original_attachment_path = Proc.new{show_unpublic_image_blog_entry_path(attachment.blog_entry_id, option)}
    end
    html << display_attachment_file(attachment,
             :attachment_path => attachment_path.call,
             :original_attachment_path => original_attachment_path.call
            )
    return html
  end
end
