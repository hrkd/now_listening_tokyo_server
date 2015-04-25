class SongController < ApplicationController
    def view
        song = Song.new()
        render :json => song.getSong(params[:station])
    end
end

