require 'geocoder/calculations'

class AdminController < ApplicationController
  def new
    return do_404 unless logged_in? && current_user.administrator?
    @this_conference = Conference.new
    @page_title = 'articles.conferences.headings.new'
  end

  def edit
    return do_404 unless logged_in? && current_user.administrator?
    @this_conference = Conference.find_by!(slug: params[:slug])
    @page_title = 'articles.conferences.headings.edit'
    @main_title_vars = { vars: { title: @this_conference.title } }
    render 'new'
  end

  def save
    conference = params[:id].present? ? Conference.find_by!(id: params[:id]) : Conference.new

    if params[:button] == 'save'
      city = City.search(params[:city])
      conference.city_id = city.id
      conference.conferencetype = params[:type]
      conference.year = params[:year].to_i
      conference.is_public = params[:is_public].present?
      conference.is_featured = params[:is_featured].present?
      conference.make_slug(true)
      conference.save!
    elsif params[:button] == 'delete'
      conference.destroy
      return redirect_to conferences_url
    end

    redirect_to conference_url(conference.slug)
  end

  rescue_from ActiveRecord::PremissionDenied do |exception|
    if logged_in?
      redirect_to :register
    else
      @register_template = :confirm_email
      @page_title = "articles.conference_registration.headings.#{@this_conference.registration_status == :open ? '': 'Pre_'}Registration_Details"
      render :register
    end
  end

  rescue_from ActiveRecord::RecordNotFound do |exception|
    do_404
  end
end
