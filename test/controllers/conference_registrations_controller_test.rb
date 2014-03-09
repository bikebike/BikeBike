require 'test_helper'

class ConferenceRegistrationsControllerTest < ActionController::TestCase
  setup do
    @conference_registration = conference_registrations(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:conference_registrations)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create conference_registration" do
    assert_difference('ConferenceRegistration.count') do
      post :create, conference_registration: { conference_id: @conference_registration.conference_id, is_attending: @conference_registration.is_attending, user_id: @conference_registration.user_id }
    end

    assert_redirected_to conference_registration_path(assigns(:conference_registration))
  end

  test "should show conference_registration" do
    get :show, id: @conference_registration
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @conference_registration
    assert_response :success
  end

  test "should update conference_registration" do
    patch :update, id: @conference_registration, conference_registration: { conference_id: @conference_registration.conference_id, is_attending: @conference_registration.is_attending, user_id: @conference_registration.user_id }
    assert_redirected_to conference_registration_path(assigns(:conference_registration))
  end

  test "should destroy conference_registration" do
    assert_difference('ConferenceRegistration.count', -1) do
      delete :destroy, id: @conference_registration
    end

    assert_redirected_to conference_registrations_path
  end
end
