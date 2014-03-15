require 'test_helper'

class WorkshopRequestedResourcesControllerTest < ActionController::TestCase
  setup do
    @workshop_requested_resource = workshop_requested_resources(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:workshop_requested_resources)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create workshop_requested_resource" do
    assert_difference('WorkshopRequestedResource.count') do
      post :create, workshop_requested_resource: { status: @workshop_requested_resource.status, workshop_id: @workshop_requested_resource.workshop_id, workshop_resource_id: @workshop_requested_resource.workshop_resource_id }
    end

    assert_redirected_to workshop_requested_resource_path(assigns(:workshop_requested_resource))
  end

  test "should show workshop_requested_resource" do
    get :show, id: @workshop_requested_resource
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @workshop_requested_resource
    assert_response :success
  end

  test "should update workshop_requested_resource" do
    patch :update, id: @workshop_requested_resource, workshop_requested_resource: { status: @workshop_requested_resource.status, workshop_id: @workshop_requested_resource.workshop_id, workshop_resource_id: @workshop_requested_resource.workshop_resource_id }
    assert_redirected_to workshop_requested_resource_path(assigns(:workshop_requested_resource))
  end

  test "should destroy workshop_requested_resource" do
    assert_difference('WorkshopRequestedResource.count', -1) do
      delete :destroy, id: @workshop_requested_resource
    end

    assert_redirected_to workshop_requested_resources_path
  end
end
