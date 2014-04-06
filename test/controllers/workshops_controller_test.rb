require 'test_helper'

class WorkshopsControllerTest < ActionController::TestCase
  setup do
    @workshop = workshops(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:workshops)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create workshop" do
    assert_difference('Workshop.count') do
      post :create, workshop: { conference_id: @workshop.conference_id, end_time: @workshop.end_time, info: @workshop.info, location_id: @workshop.location_id, min_facilitators: @workshop.min_facilitators, slug: @workshop.slug, start_time: @workshop.start_time, title: @workshop.title, workshop_presentation_style: @workshop.workshop_presentation_style, workshop_stream_id: @workshop.workshop_stream_id }
    end

    assert_redirected_to workshop_path(assigns(:workshop))
  end

  test "should show workshop" do
    get :show, id: @workshop
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @workshop
    assert_response :success
  end

  test "should update workshop" do
    patch :update, id: @workshop, workshop: { conference_id: @workshop.conference_id, end_time: @workshop.end_time, info: @workshop.info, location_id: @workshop.location_id, min_facilitators: @workshop.min_facilitators, slug: @workshop.slug, start_time: @workshop.start_time, title: @workshop.title, workshop_presentation_style: @workshop.workshop_presentation_style, workshop_stream_id: @workshop.workshop_stream_id }
    assert_redirected_to workshop_path(assigns(:workshop))
  end

  test "should destroy workshop" do
    assert_difference('Workshop.count', -1) do
      delete :destroy, id: @workshop
    end

    assert_redirected_to workshops_path
  end
end
