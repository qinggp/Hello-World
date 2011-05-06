# to_xsを無効化する
#
# XMLBuilderの日本語表示が文字実体参照になってしまうため
class String
  def to_xs
    ERB::Util.h(unpack('U*').pack('U*')).gsub("'", '&apos;') # ASCII, UTF-8
  rescue
    unpack('C*').map {|n| n.xchr}.join # ISO-8859-1, WIN-1252
  end
end
