module NavigationHelpers
  def path_to(page_name)
    case page_name
    when /^landing$/i
      path = 'root'
    end

    begin
      self.send((path + '_url').to_sym)
    rescue Object => e
      raise "Can't find mapping from \"#{page_name}\" to a path.\n" +
        "#{path}_url\n" +
        "Now, go and add a mapping in #{__FILE__}"
    end
  end
end

World(NavigationHelpers)
