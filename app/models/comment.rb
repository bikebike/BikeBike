class Comment < ActiveRecord::Base
  belongs_to :user

  def comment_object
    model_type.classify.constantize.find(model_id)
  end

  def set_model(model)
    model_type = model.class.name.tableize
    model_id = model.id
  end

  def self.for(model)
    where(model_type: model.class.name.tableize, model_id: model.id).order(created_at: :asc)
  end

  def self.create_for(model, user, comment)
    create(
      model_type: model.class.name.tableize,
      model_id: model.id,
      user_id: user.id,
      comment: comment
    )
  end

    def add_comment(user, comment)
        Comment.create_for(self, user, comment)
    end

    def comments
        Comment.for(self)
    end

    def reply?
      model_type == 'comments'
    end
end
