class TrackCountNotifiler < Mars::Iso2022jpMailer
  include Mars::MailSendable

  # あしあとお知らせメール
  def notification(options)
    track = options[:track]
    setup_subject!("あしあと#{options[:track_count]}件目はこの方です！")
    @body["track_count"] = options[:track_count]
    @body["visitor"] = track.visitor
    @body["user"] = track.user
    @body["visitor_url"] = user_url(track.visitor.id, :host => CONFIG["host"])
    setup_send_info!(:user => track.user)
  end
end
