class TracksController < ApplicationController

  access_control do
    allow logged_in
  end

  def index
    default_track
  end

  def search
    if !params[:specific_number].blank? && Track.range_of_total_count?(current_user, params[:specific_number].to_i)
      @tracks = Track.by_user(current_user)
      specific_number(params[:specific_number])
    elsif !params[:split_number].blank? && Track.range_of_total_count?(current_user, params[:split_number].to_i)
      @tracks = Track.split(params[:split_number].to_i, current_user)
    else
      default_track
    end
    render "index"
  end

  # コントローラ単位でのコンテンツホームのパスを返す
  def contents_home_path
    tracks_path
  end

  private

  def default_track
    @total_visitor = Track.total_visitor(current_user)
    @tracks = Track.by_user(current_user)
    @total_access = @tracks.count
    group_by_visitor
    latest
  end

  def group_by_visitor
    @tracks = @tracks.group_by_visitor
  end

  def latest
    @tracks = @tracks.latest
  end

  def specific_number(number)
    @tracks = @tracks.specific_number(number.to_i)
  end

  def split_number(number)
    @tracks = @tracks.split_number(number.to_i)
  end
end
