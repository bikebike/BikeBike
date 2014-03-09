require 'test_helper'

class OrganizationsControllerTest < ActionController::TestCase
  setup do
    @organization = organizations(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:organizations)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create organization" do
    assert_difference('Organization.count') do
      post :create, organization: { avatar: @organization.avatar, email_address: @organization.email_address, info: @organization.info, location_id: @organization.location_id, logo: @organization.logo, name: @organization.name, requires_approval: @organization.requires_approval, secret_answer: @organization.secret_answer, secret_question: @organization.secret_question, slug: @organization.slug, url: @organization.url, user_organization_replationship_id: @organization.user_organization_replationship_id, year_founded: @organization.year_founded }
    end

    assert_redirected_to organization_path(assigns(:organization))
  end

  test "should show organization" do
    get :show, id: @organization
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @organization
    assert_response :success
  end

  test "should update organization" do
    patch :update, id: @organization, organization: { avatar: @organization.avatar, email_address: @organization.email_address, info: @organization.info, location_id: @organization.location_id, logo: @organization.logo, name: @organization.name, requires_approval: @organization.requires_approval, secret_answer: @organization.secret_answer, secret_question: @organization.secret_question, slug: @organization.slug, url: @organization.url, user_organization_replationship_id: @organization.user_organization_replationship_id, year_founded: @organization.year_founded }
    assert_redirected_to organization_path(assigns(:organization))
  end

  test "should destroy organization" do
    assert_difference('Organization.count', -1) do
      delete :destroy, id: @organization
    end

    assert_redirected_to organizations_path
  end
end
