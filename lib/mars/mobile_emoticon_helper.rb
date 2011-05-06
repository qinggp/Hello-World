# 携帯絵文字のUTF-8文字コード返却
#
# 文字コードと絵文字のマッピングは以下サイトを参考にした。
# http://www.nttdocomo.co.jp/service/imode/make/content/pictograph/basic/
module Mars::MobileEmoticonHelper
  # 絵文字 1
  def emoticon_1
    return [0xE6E2].pack("U")
  end

  # 絵文字 2
  def emoticon_2
    return [0xE6E3].pack("U")
  end

  # 絵文字 3
  def emoticon_3
    return [0xE6E4].pack("U")
  end

  # 絵文字 4
  def emoticon_4
    return [0xE6E5].pack("U")
  end

  # 絵文字 5
  def emoticon_5
    return [0xE6E6].pack("U")
  end

  # 絵文字 6
  def emoticon_6
    return [0xE6E7].pack("U")
  end

  # 絵文字 7
  def emoticon_7
    return [0xE6E8].pack("U")
  end

  # 絵文字 8
  def emoticon_8
    return [0xE6E9].pack("U")
  end

  # 絵文字 9
  def emoticon_9
    return [0xE6EA].pack("U")
  end

  # 絵文字 0
  def emoticon_0
    return [0xE6EB].pack("U")
  end

  # 絵文字 電話
  def emoticon_phone
    return [0xE687].pack("U")
  end

  # 絵文字 携帯電話
  def emoticon_mobile_phone
    return [0xE688].pack("U")
  end

  # 絵文字 メール
  def emoticon_mail
    return [0xE6D3].pack("U")
  end

  # 絵文字 スケジュール
  def emoticon_schedule
    return [0xE689].pack("U")
  end
end
