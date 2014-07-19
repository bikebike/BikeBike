SitemapGenerator::Sitemap.default_host = "http://hackingoff.com"

SitemapGenerator::Sitemap.create do
	routes = Rails.application.routes.routes.map do |route|
		{alias: route.name, path: route.path.spec.to_s, controller: route.defaults[:controller], action: route.defaults[:action]}
	end

	# Set a list of controllers you don't want to generate routes for.
	# /rails/info in particular maps to something inaccessible.
	# redirects have a nil controller. This prevents duplicate content penalties.
	banned_controllers = ["rails/info", nil]
	routes.reject! {|route| banned_controllers.include?(route[:controller])}

	# sitemap_generator includes root by default; prevent duplication
	routes.reject! {|route| route[:path] == '/'}

	routes.each {|route| add route[:path][0..-11]} # Strips off '(.:format)

	# Notice the below if you're hosting Jekyll/Octopress in a subdirectory
	# or otherwise want to index content outside of Rails' routes.
	# add_to_index '/path/sitemap.xml'