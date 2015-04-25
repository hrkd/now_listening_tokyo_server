class Song
    # HTTParty
    include HTTParty
    $urls = {
        'jwave'=> 'http://www.j-wave.co.jp/top/xml/now_on_air_song.xml',
        'tfm'=> 'http://www.tfm.co.jp/top/xml/noamusic.xml',
    }

    def getSong(station)
        if !$urls.key?(station)
            return {}
        end
        response = HTTParty.get($urls[station])

        if station == 'jwave'
            return getJwave(response)
        else station == 'tfm'
            return getTfm(response)
        end
    end

    private
    def getJwave(response)
        txt = response["now_on_air_song"]["data"]["information"]
        res = txt.scan(/^「(.*?)」\s(.*?)\s(\d{2}:\d{2})/)

        return  {
            "title"=> res[0][0],
            "artist"=>res[0][1],
            "time"=>res[0][2]
        }
    end

    private
    def getTfm(response)
        txt = response["item"]
        return {
            "title"=> txt['music_name']["__content__"],
            "artist"=>txt['artist_name'],
            "time"=>txt['onair_time']
        }
    end
end
