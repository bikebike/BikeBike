require 'test_helper'

class ConferenceTypesControllerTest < ActionController::TestCase
  setup do
    @conference_type = conference_types(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:conference_types)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create conference_type" do
    assert_difference('ConferenceType.count') do
      post :create, conference_type: { info: @conference_type.info, title: @conference_type.title }
    end

    assert_redirected_to conference_type_path(assigns(:conference_type))
  end

  test "should show conference_type" do
    get :show, id: @conference_type
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @conference_type
    assert_response :success
  end

  test "should update conference_type" do
    patch :update, id: @conference_type, conference_type: { info: @conference_type.info, title: @conference_type.title }
    assert_redirected_to conference_type_path(assigns(:conference_type))
  end

  test "should destroy conference_type" do
    assert_difference('ConferenceType.count', -1) do
      delete :destroy, id: @conference_type
    end

    assert_redirected_to conference_types_path
  end
end
