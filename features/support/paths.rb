module NavigationHelpers
	def path_to(path)
		path = path.to_sym

		case path
			when /^landing$/i
				path = :home
			when /^registration$/i
				path = "/conferences/#{@last_conference.slug}/register/"
			when /^edit conference$/i
				path = "/conferences/#{@last_conference.slug}/edit/"
			when /^(workshops|stats|broadcast)$/i
				path = "/conferences/#{@last_conference.slug}/#{path}/"
			when /^(stats.xls)$/i
				path = "/conferences/#{@last_conference.slug}/stats.xls"
		end

		if path.is_a?(Symbol)
			begin
				path = Rails.application.routes.url_helpers.send("#{path}_path".to_sym)
			rescue Object => e
				raise "Can't find mapping from \"#{path}\" to a path."
			end
		end

		if path.blank?
			raise "Can't find mapping from \"#{page_name}\" to a path."
		end

		return path
	end
end

World(NavigationHelpers)
