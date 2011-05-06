# 日本語のファイル名をサニタイズしていたので、扱えるように変更
module Mars::FileColumn
  def self.included(recipient)
    recipient.class_eval {
      private
      def self.sanitize_filename(filename)
        filename = File.basename(filename.gsub("\\", "/")) # work-around for IE
        filename.gsub!(/[^\w\.\-\+_]/,"_")  # ここを変更
        filename = "_#{filename}" if filename =~ /^\.+$/
        filename = "unnamed" if filename.size == 0
        filename
      end
    }
  end
end
