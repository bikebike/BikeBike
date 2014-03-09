require 'test_helper'

class ConferenceRegistrationResponsesControllerTest < ActionController::TestCase
  setup do
    @conference_registration_response = conference_registration_responses(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:conference_registration_responses)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create conference_registration_response" do
    assert_difference('ConferenceRegistrationResponse.count') do
      post :create, conference_registration_response: { conference_registration_id: @conference_registration_response.conference_registration_id, data: @conference_registration_response.data, registration_form_field_id: @conference_registration_response.registration_form_field_id }
    end

    assert_redirected_to conference_registration_response_path(assigns(:conference_registration_response))
  end

  test "should show conference_registration_response" do
    get :show, id: @conference_registration_response
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @conference_registration_response
    assert_response :success
  end

  test "should update conference_registration_response" do
    patch :update, id: @conference_registration_response, conference_registration_response: { conference_registration_id: @conference_registration_response.conference_registration_id, data: @conference_registration_response.data, registration_form_field_id: @conference_registration_response.registration_form_field_id }
    assert_redirected_to conference_registration_response_path(assigns(:conference_registration_response))
  end

  test "should destroy conference_registration_response" do
    assert_difference('ConferenceRegistrationResponse.count', -1) do
      delete :destroy, id: @conference_registration_response
    end

    assert_redirected_to conference_registration_responses_path
  end
end
