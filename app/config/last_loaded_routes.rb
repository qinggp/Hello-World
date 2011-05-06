# このroutesは一番最後にロードされます。
# したがって、拡張機能で定義されたroutes.rbよりも後に定義されます。
ActionController::Routing::Routes.draw do |map|
  map.connect ':controller', :action => "index"
  map.connect ':controller/:action'
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
end
