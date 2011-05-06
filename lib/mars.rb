module Mars
  class ConfError < StandardError; end
  class AccessDenied < StandardError; end

  ALL_PAGES = 0 # ページネーションで使用するper_pageパラメータがこの値のとき、全件表示
  IMAGE_EXT_REGEX = /.*\.(gif|jpe?g|png)$/ # アップロードされる画像ファイルの拡張子パターン
  COPY_RIGHT = "Copyright (C) Network Applied Communication Laboratory Ltd."

  # バリデーションに使用
  EMAIL_REGEX = /\A[0-9A-Za-z._-]*@[0-9A-Za-z._-]*\z/
  EN_ONE_BYTE_CHARS_AND_NUM_REGEX = /\A[0-9A-Za-z]*\z/
  BAD_EMAIL_MESSAGE = "は半角英数でxxx@xxx.xxxの形式で入力してください。".freeze
  BAD_EN_ONE_BYTE_CHARS_AND_NUM_MESSAGE = "は半角英数字の形式で入力してください。".freeze
end
