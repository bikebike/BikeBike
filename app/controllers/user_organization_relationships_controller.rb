class UserOrganizationRelationshipsController < ApplicationController
  before_action :set_user_organization_relationship, only: [:show, :edit, :update, :destroy]

  # GET /user_organization_relationships
  def index
    @user_organization_relationships = UserOrganizationRelationship.all
  end

  # GET /user_organization_relationships/1
  def show
  end

  # GET /user_organization_relationships/new
  def new
    @user_organization_relationship = UserOrganizationRelationship.new
  end

  # GET /user_organization_relationships/1/edit
  def edit
  end

  # POST /user_organization_relationships
  def create
    @user_organization_relationship = UserOrganizationRelationship.new(user_organization_relationship_params)

    if @user_organization_relationship.save
      redirect_to @user_organization_relationship, notice: 'User organization relationship was successfully created.'
    else
      render action: 'new'
    end
  end

  # PATCH/PUT /user_organization_relationships/1
  def update
    if @user_organization_relationship.update(user_organization_relationship_params)
      redirect_to @user_organization_relationship, notice: 'User organization relationship was successfully updated.'
    else
      render action: 'edit'
    end
  end

  # DELETE /user_organization_relationships/1
  def destroy
    @user_organization_relationship.destroy
    redirect_to user_organization_relationships_url, notice: 'User organization relationship was successfully destroyed.'
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_user_organization_relationship
      @user_organization_relationship = UserOrganizationRelationship.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def user_organization_relationship_params
      params.require(:user_organization_relationship).permit(:user_id, :organization_id, :relationship)
    end
end
