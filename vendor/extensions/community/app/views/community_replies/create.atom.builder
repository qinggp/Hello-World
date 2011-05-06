xml.instruct!
xml.entry(:language => "ja-JP", 'xmlns' => 'http://www.w3.org/2005/Atom', 'xmlns:mars' => request.protocol + request.host_with_port) do |entry|
  render :partial => "entry_subelements", :locals => {:comment => @reply, :entry => entry}
end
