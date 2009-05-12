ActionController::Routing::Routes.draw do |map|
  # The priority is based upon order of creation: first created -> highest priority.

  # Sample of regular route:
  #   map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   map.resources :products

  # Sample resource route with options:
  #   map.resources :products, :member => { :short => :get, :toggle => :post }, :collection => { :sold => :get }

  # Sample resource route with sub-resources:
  #   map.resources :products, :has_many => [ :comments, :sales ], :has_one => :seller

  # Sample resource route within a namespace:
  #   map.namespace :admin do |admin|
  #     # Directs /admin/products/* to Admin::ProductsController (app/controllers/admin/products_controller.rb)
  #     admin.resources :products
  #   end

  # You can have the root of your site routed with map.root -- just remember to delete public/index.html.
  # map.root :controller => "welcome"

  # See how all your routes lay out with "rake routes"
  
  # playlist
  map.connect '/recommendation/playlist.m3u', :controller => 'recommendation', :action => 'playlist', :format => 'm3u'
  map.connect '/playlist/', :controller => 'recommendation', :action => 'playlist'
  
  # recommendation
  map.connect '', :controller => 'recommendation'
  map.connect '/recommendation/user/:username', :controller => 'recommendation', :action => 'user'
  map.connect '/recommendation/automatron/:username.xml', :controller => 'recommendation', :action => 'automatron', :format => 'xml'
  map.connect '/recommendation/artist/:query', :controller => 'recommendation', :action => 'artist'
  
  # artist
  map.connect '/artist/show/:name', :controller => 'artist', :action => 'show'
  
  map.connect 'about', :controller => 'home', :action => 'about'
  map.connect 'contact', :controller => 'home', :action => 'contact'
  map.connect 'api', :controller => 'home', :action => 'api'
  map.connect 'stats', :controller => 'home', :action => 'stats'
  map.connect 'recommendation_sources', :controller => 'home', :action => 'recommendation_sources'
  map.connect 'new_features', :controller => 'home', :action => 'new_features'
  map.connect 'name', :controller => 'name'
  map.connect 'buy', :controller => 'buy'


  map.connect 'blog', :controller => 'blog_post'
  map.connect 'blog/rss', :controller => 'blog_post', :action => 'rss'
  map.connect 'blog/show/:id', :controller => 'blog_post', :action => 'show'
  map.connect 'blog/ip', :controller => 'blog_post', :action => 'ip'
  map.connect 'blog/new', :controller => 'blog_post', :action => 'new'
  map.connect 'blog/create', :controller => 'blog_post', :action => 'create'
  map.connect 'blog/edit/:id', :controller => 'blog_post', :action => 'edit'
  map.connect 'blog/edit_iphone/:id', :controller => 'blog_post', :action => 'edit_iphone'
  map.connect 'blog/update/:id', :controller => 'blog_post', :action => 'update'
  map.connect 'blog/destroy/:id', :controller => 'blog_post', :action => 'destroy'

  # Install the default routes as the lowest priority.
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
end
