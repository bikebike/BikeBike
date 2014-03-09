require 'test_helper'

class WorkshopStreamsControllerTest < ActionController::TestCase
  setup do
    @workshop_stream = workshop_streams(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:workshop_streams)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create workshop_stream" do
    assert_difference('WorkshopStream.count') do
      post :create, workshop_stream: { info: @workshop_stream.info, name: @workshop_stream.name, slug: @workshop_stream.slug }
    end

    assert_redirected_to workshop_stream_path(assigns(:workshop_stream))
  end

  test "should show workshop_stream" do
    get :show, id: @workshop_stream
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @workshop_stream
    assert_response :success
  end

  test "should update workshop_stream" do
    patch :update, id: @workshop_stream, workshop_stream: { info: @workshop_stream.info, name: @workshop_stream.name, slug: @workshop_stream.slug }
    assert_redirected_to workshop_stream_path(assigns(:workshop_stream))
  end

  test "should destroy workshop_stream" do
    assert_difference('WorkshopStream.count', -1) do
      delete :destroy, id: @workshop_stream
    end

    assert_redirected_to workshop_streams_path
  end
end
