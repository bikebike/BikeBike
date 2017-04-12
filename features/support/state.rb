module TestState
  class Store
    attr_accessor :last_email_entered
    attr_accessor :last_conference
    attr_accessor :last_registration
    attr_accessor :last_organization
    attr_accessor :last_email
    attr_accessor :it
    attr_accessor :last_page

    def my_account=(user)
      @my_account = user
    end

    def my_account
      @my_account ||= User.find_by(email: last_email_entered)
    end

    def my_registration=(reg)
      @my_registration = reg
    end

    def my_registration
      @my_registration ||= ConferenceRegistration.find_by(user_id: my_account.id)
    end

    def last_token=(token)
      @last_token = token
    end

    def last_token
      @last_token ||= EmailConfirmation.where(user_id: my_account.id).last.token
    end

    def last_workshop=(workshop)
      @last_workshop = workshop
    end

    def last_workshop
      @last_workshop ||= Workshop.all.last
    end
  end

  module Values
    class << self
      def []=(key, value)
        @my_values ||= {}
        @my_values[key.to_sym] = value
      end

      def [](key)
        @my_values ||= {}
        return @my_values[key.to_sym]
      end
    end
  end

  module Users
    class << self
      def []=(username, user)
        @users ||= {}
        @users[username.to_s] = user
      end

      def [](username)
        @users ||= {}
        return @users[username.to_s]
      end
    end
  end

  class Sample
    def self.[](type)
      @types ||= {}
      @types[type.to_sym] ||= Sample.new(type)
      return @types[type.to_sym]
    end

    def method_missing(method_sym, *arguments, &block)
      @arrays ||= {}
      unless @arrays[method_sym].present?
        @arrays[method_sym] = {
          array: Object.const_get(@type.to_s.camelize).send(method_sym, *arguments, &block)
        }
      end

      if @arrays[method_sym][:last].present?
        @arrays[method_sym][:last] += 1
        @arrays[method_sym][:last] = 0 if @arrays[method_sym][:last] >= @arrays[method_sym][:array].length
      else
        @arrays[method_sym][:last] = 0
      end

      return @arrays[method_sym][:array][@arrays[method_sym][:last]]
    end

    private
    def initialize(type)
      @type = type
    end
  end

  class << self
    def reset!
      @store = nil
    end

    def method_missing(method_sym, *arguments, &block)
      @store ||= Store.new
      @store.send(method_sym, *arguments, &block)
    end
  end
end
