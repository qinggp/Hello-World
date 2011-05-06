begin
  # rqrcode customize
  require "mars/qrcode_rmagick"
  RQRCode::QRCode.send(:include, Mars::QRCodeRMagick)

  # file column settings
  if RAILS_ENV == "test"
    FileColumn::ClassMethods::DEFAULT_OPTIONS[:root_path] =
      File.join(RAILS_ROOT, "test", "tmp", "file_column")
  else
    FileColumn::ClassMethods::DEFAULT_OPTIONS[:root_path] =
          File.join(RAILS_ROOT, "file_column", RAILS_ENV)
    FileColumn::ClassMethods::DEFAULT_OPTIONS[:permissions] = 0777
  end

  # calendar helper settings
  Mars::CalendarHelperDayNames = ["日", "月", "火", "水", "木", "金", "土"]

  # acl9
  Acl9.config[:protect_global_roles] = true

  require File.join(RAILS_ROOT, "vendor/plugins/mars_bugfix/lib/to_xs_disablement_for_xml_builder")
  require File.join(RAILS_ROOT, "vendor/plugins/mars_bugfix/lib/theme_image_path_fix")

  # open_id_authentication i18n
  OpenIdAuthentication::Result::ERROR_MESSAGES[:missing] = I18n.t("open_id.errors.missing")
  OpenIdAuthentication::Result::ERROR_MESSAGES[:invalid] = I18n.t("open_id.errors.invalid")
  OpenIdAuthentication::Result::ERROR_MESSAGES[:canceled] = I18n.t("open_id.errors.canceled")
  OpenIdAuthentication::Result::ERROR_MESSAGES[:failed] = I18n.t("open_id.errors.failed")
  OpenIdAuthentication::Result::ERROR_MESSAGES[:setup_needed] = I18n.t("open_id.errors.setup_needed")
rescue Exception => ex
  puts "fail to customize existing plugin or library for mars."
  puts "please edit \"#{__FILE__}\" or required files."
  puts $!.class.to_s
  puts $!.to_s
  puts $@.join("\n")
end
