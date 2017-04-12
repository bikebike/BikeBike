module NavigationHelpers
  def path_to(path)
    path = path.to_sym
    args = []

    case path
    when /^landing$/i
      path = :home
    when /^(my )?workshop$/i
      path = :view_workshop
      args << TestState.last_conference.slug
      args << TestState.last_workshop.id
    when /^registration$/i
      path = :register
      args << TestState.last_conference.slug
    when /^(conference|register|workshops)$/i
      args << TestState.last_conference.slug
    when /^confirm(ation)?$/
      path = :confirm
      args << TestState.last_token
    when /^google maps$/
      path = /^https?:\/\/www\.google\.com\/maps\/place\/.*/
    end

    if path.is_a?(Symbol)
      path = Rails.application.routes.url_helpers.send("#{path}_path".to_sym, *args)
    end

    raise "Can't find mapping from \"#{path}\" to a path." unless path.present?

    return path
  end
end

World(NavigationHelpers)
