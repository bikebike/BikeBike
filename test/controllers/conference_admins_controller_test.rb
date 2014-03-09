require 'test_helper'

class ConferenceAdminsControllerTest < ActionController::TestCase
  setup do
    @conference_admin = conference_admins(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:conference_admins)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create conference_admin" do
    assert_difference('ConferenceAdmin.count') do
      post :create, conference_admin: { conference_id: @conference_admin.conference_id, user_id: @conference_admin.user_id }
    end

    assert_redirected_to conference_admin_path(assigns(:conference_admin))
  end

  test "should show conference_admin" do
    get :show, id: @conference_admin
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @conference_admin
    assert_response :success
  end

  test "should update conference_admin" do
    patch :update, id: @conference_admin, conference_admin: { conference_id: @conference_admin.conference_id, user_id: @conference_admin.user_id }
    assert_redirected_to conference_admin_path(assigns(:conference_admin))
  end

  test "should destroy conference_admin" do
    assert_difference('ConferenceAdmin.count', -1) do
      delete :destroy, id: @conference_admin
    end

    assert_redirected_to conference_admins_path
  end
end
