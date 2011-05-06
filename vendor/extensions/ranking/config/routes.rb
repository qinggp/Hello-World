ActionController::Routing::Routes.draw do |map|
  map.rankings "/rankings/:action", :controller => "rankings"
end
