class SongController < ApplicationController
    protect_from_forgery except: :view

    def view
        song = Song.new()
        render :json => song.getSong(params[:station]), callback: params[:callback]
    end
end

