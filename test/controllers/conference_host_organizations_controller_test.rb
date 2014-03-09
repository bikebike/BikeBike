require 'test_helper'

class ConferenceHostOrganizationsControllerTest < ActionController::TestCase
  setup do
    @conference_host_organization = conference_host_organizations(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:conference_host_organizations)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create conference_host_organization" do
    assert_difference('ConferenceHostOrganization.count') do
      post :create, conference_host_organization: { conference_id: @conference_host_organization.conference_id, order: @conference_host_organization.order, organization_id: @conference_host_organization.organization_id }
    end

    assert_redirected_to conference_host_organization_path(assigns(:conference_host_organization))
  end

  test "should show conference_host_organization" do
    get :show, id: @conference_host_organization
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @conference_host_organization
    assert_response :success
  end

  test "should update conference_host_organization" do
    patch :update, id: @conference_host_organization, conference_host_organization: { conference_id: @conference_host_organization.conference_id, order: @conference_host_organization.order, organization_id: @conference_host_organization.organization_id }
    assert_redirected_to conference_host_organization_path(assigns(:conference_host_organization))
  end

  test "should destroy conference_host_organization" do
    assert_difference('ConferenceHostOrganization.count', -1) do
      delete :destroy, id: @conference_host_organization
    end

    assert_redirected_to conference_host_organizations_path
  end
end
