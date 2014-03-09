require 'test_helper'

class WorkshopResourcesControllerTest < ActionController::TestCase
  setup do
    @workshop_resource = workshop_resources(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:workshop_resources)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create workshop_resource" do
    assert_difference('WorkshopResource.count') do
      post :create, workshop_resource: { info: @workshop_resource.info, name: @workshop_resource.name, slug: @workshop_resource.slug }
    end

    assert_redirected_to workshop_resource_path(assigns(:workshop_resource))
  end

  test "should show workshop_resource" do
    get :show, id: @workshop_resource
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @workshop_resource
    assert_response :success
  end

  test "should update workshop_resource" do
    patch :update, id: @workshop_resource, workshop_resource: { info: @workshop_resource.info, name: @workshop_resource.name, slug: @workshop_resource.slug }
    assert_redirected_to workshop_resource_path(assigns(:workshop_resource))
  end

  test "should destroy workshop_resource" do
    assert_difference('WorkshopResource.count', -1) do
      delete :destroy, id: @workshop_resource
    end

    assert_redirected_to workshop_resources_path
  end
end
