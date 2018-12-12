class ArtistsController < ApplicationController
  respond_to :html, :json

  def index
    @user = current_user

    @artists = Artist.followed_by(@user).with_name.order(name: :asc).distinct

    respond_with @artists
  end

  def show
    @user = current_user

    @artist = Artist.where(id: params[:id]).first

    @albums = @artist.albums.order(release_date: :desc).types_for_user(@user)
    @music_videos = @artist.music_videos.order(release_date: :desc)

    respond_with @artist
  end

  def follow
    @artist = Artist.find(params[:id])

    follow = Follow.where(user: current_user, artist: @artist).first_or_initialize
    follow.active = true
    follow.save!

    if request.xhr?
      render json: {
        artist: render_to_string('artists/_follow',
          layout: false, locals: { artist: @artist }
        )
      }
    else
      redirect_to artist_path(@artist)
    end
  end

  def unfollow
    @artist = Artist.find(params[:id])

    follow = Follow.where(user: current_user, artist: @artist).first_or_initialize
    follow.active = false
    follow.save!

    if request.xhr?
      render json: {
        artist: render_to_string('artists/_follow',
          layout: false, locals: { artist: @artist }
        )
      }
    else
      redirect_to artist_path(@artist)
    end
  end

  def search
    @artists = Artist.basic_search(name: params[:artist])
      .left_joins(:follows)
      .group(:id)
      .reorder('COUNT(follows.artist_id) DESC')
      .limit(50)
  end
end