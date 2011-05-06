# <%= file_name.classify %>機能UI拡張ヘルパ
#
# <%= extension_file_name %>.rb で ui に部分テンプレートを追加する際、
# 何も指定しなければこのヘルパモジュールを利用します。
#
# NOTE: 名前衝突の恐れがあるため「<%= file_name %>_」をメソッド名先頭に
# 付けてください。
module <%= file_name.classify %>PartHelper
end
