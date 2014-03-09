require 'test_helper'

class WorkshopPresentationStylesControllerTest < ActionController::TestCase
  setup do
    @workshop_presentation_style = workshop_presentation_styles(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:workshop_presentation_styles)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create workshop_presentation_style" do
    assert_difference('WorkshopPresentationStyle.count') do
      post :create, workshop_presentation_style: { info: @workshop_presentation_style.info, name: @workshop_presentation_style.name, slug: @workshop_presentation_style.slug }
    end

    assert_redirected_to workshop_presentation_style_path(assigns(:workshop_presentation_style))
  end

  test "should show workshop_presentation_style" do
    get :show, id: @workshop_presentation_style
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @workshop_presentation_style
    assert_response :success
  end

  test "should update workshop_presentation_style" do
    patch :update, id: @workshop_presentation_style, workshop_presentation_style: { info: @workshop_presentation_style.info, name: @workshop_presentation_style.name, slug: @workshop_presentation_style.slug }
    assert_redirected_to workshop_presentation_style_path(assigns(:workshop_presentation_style))
  end

  test "should destroy workshop_presentation_style" do
    assert_difference('WorkshopPresentationStyle.count', -1) do
      delete :destroy, id: @workshop_presentation_style
    end

    assert_redirected_to workshop_presentation_styles_path
  end
end
