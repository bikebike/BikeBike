require 'test_helper'

class RegistrationFormFieldsControllerTest < ActionController::TestCase
  setup do
    @registration_form_field = registration_form_fields(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:registration_form_fields)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create registration_form_field" do
    assert_difference('RegistrationFormField.count') do
      post :create, registration_form_field: { field_type: @registration_form_field.field_type, help: @registration_form_field.help, is_retired: @registration_form_field.is_retired, options: @registration_form_field.options, required: @registration_form_field.required, title: @registration_form_field.title }
    end

    assert_redirected_to registration_form_field_path(assigns(:registration_form_field))
  end

  test "should show registration_form_field" do
    get :show, id: @registration_form_field
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @registration_form_field
    assert_response :success
  end

  test "should update registration_form_field" do
    patch :update, id: @registration_form_field, registration_form_field: { field_type: @registration_form_field.field_type, help: @registration_form_field.help, is_retired: @registration_form_field.is_retired, options: @registration_form_field.options, required: @registration_form_field.required, title: @registration_form_field.title }
    assert_redirected_to registration_form_field_path(assigns(:registration_form_field))
  end

  test "should destroy registration_form_field" do
    assert_difference('RegistrationFormField.count', -1) do
      delete :destroy, id: @registration_form_field
    end

    assert_redirected_to registration_form_fields_path
  end
end
