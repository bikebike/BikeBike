require 'test_helper'

class ConferenceRegistratonFormFieldsControllerTest < ActionController::TestCase
  setup do
    @conference_registraton_form_field = conference_registraton_form_fields(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:conference_registraton_form_fields)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create conference_registraton_form_field" do
    assert_difference('ConferenceRegistratonFormField.count') do
      post :create, conference_registraton_form_field: { conference_id: @conference_registraton_form_field.conference_id, order: @conference_registraton_form_field.order, registration_form_field_id: @conference_registraton_form_field.registration_form_field_id }
    end

    assert_redirected_to conference_registraton_form_field_path(assigns(:conference_registraton_form_field))
  end

  test "should show conference_registraton_form_field" do
    get :show, id: @conference_registraton_form_field
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @conference_registraton_form_field
    assert_response :success
  end

  test "should update conference_registraton_form_field" do
    patch :update, id: @conference_registraton_form_field, conference_registraton_form_field: { conference_id: @conference_registraton_form_field.conference_id, order: @conference_registraton_form_field.order, registration_form_field_id: @conference_registraton_form_field.registration_form_field_id }
    assert_redirected_to conference_registraton_form_field_path(assigns(:conference_registraton_form_field))
  end

  test "should destroy conference_registraton_form_field" do
    assert_difference('ConferenceRegistratonFormField.count', -1) do
      delete :destroy, id: @conference_registraton_form_field
    end

    assert_redirected_to conference_registraton_form_fields_path
  end
end
