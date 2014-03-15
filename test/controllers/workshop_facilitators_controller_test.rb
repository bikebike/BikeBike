require 'test_helper'

class WorkshopFacilitatorsControllerTest < ActionController::TestCase
  setup do
    @workshop_facilitator = workshop_facilitators(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:workshop_facilitators)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create workshop_facilitator" do
    assert_difference('WorkshopFacilitator.count') do
      post :create, workshop_facilitator: { role: @workshop_facilitator.role, user_id: @workshop_facilitator.user_id, workshop_id: @workshop_facilitator.workshop_id }
    end

    assert_redirected_to workshop_facilitator_path(assigns(:workshop_facilitator))
  end

  test "should show workshop_facilitator" do
    get :show, id: @workshop_facilitator
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @workshop_facilitator
    assert_response :success
  end

  test "should update workshop_facilitator" do
    patch :update, id: @workshop_facilitator, workshop_facilitator: { role: @workshop_facilitator.role, user_id: @workshop_facilitator.user_id, workshop_id: @workshop_facilitator.workshop_id }
    assert_redirected_to workshop_facilitator_path(assigns(:workshop_facilitator))
  end

  test "should destroy workshop_facilitator" do
    assert_difference('WorkshopFacilitator.count', -1) do
      delete :destroy, id: @workshop_facilitator
    end

    assert_redirected_to workshop_facilitators_path
  end
end
