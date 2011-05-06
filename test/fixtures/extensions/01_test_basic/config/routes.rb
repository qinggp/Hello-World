ActionController::Routing::Routes.draw do |map|
  map.connect '/your/routing', :controller => 'test_basic_extension', :action => 'routing'
end
