require 'test_helper'

class ConferencesControllerTest < ActionController::TestCase
  setup do
    @conference = conferences(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:conferences)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create conference" do
    assert_difference('Conference.count') do
      post :create, conference: { banner: @conference.banner, conference_type: @conference.conference_type, end_date: @conference.end_date, info: @conference.info, meal_info: @conference.meal_info, meals_provided: @conference.meals_provided, poster: @conference.poster, registration_open: @conference.registration_open, slug: @conference.slug, start_date: @conference.start_date, title: @conference.title, travel_info: @conference.travel_info, workshop_schedule_published: @conference.workshop_schedule_published }
    end

    assert_redirected_to conference_path(assigns(:conference))
  end

  test "should show conference" do
    get :show, id: @conference
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @conference
    assert_response :success
  end

  test "should update conference" do
    patch :update, id: @conference, conference: { banner: @conference.banner, conference_type: @conference.conference_type, end_date: @conference.end_date, info: @conference.info, meal_info: @conference.meal_info, meals_provided: @conference.meals_provided, poster: @conference.poster, registration_open: @conference.registration_open, slug: @conference.slug, start_date: @conference.start_date, title: @conference.title, travel_info: @conference.travel_info, workshop_schedule_published: @conference.workshop_schedule_published }
    assert_redirected_to conference_path(assigns(:conference))
  end

  test "should destroy conference" do
    assert_difference('Conference.count', -1) do
      delete :destroy, id: @conference
    end

    assert_redirected_to conferences_path
  end
end
