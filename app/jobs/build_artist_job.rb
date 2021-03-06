class BuildArtistJob
  include Sidekiq::Worker
  sidekiq_options :queue => :default

  def perform(artist_id)
    artist = Artist.find artist_id
    days = 1
    last_release_date = artist.albums.order('release_date desc').first&.release_date

    if last_release_date.present?
      case
        when last_release_date < 30.years.ago
          days = 30
        when last_release_date < 20.years.ago
          days = 20
        when last_release_date < 10.years.ago
          days = 10
        when last_release_date < 5.years.ago
          days = 5
        else
          days = 1
      end
    end

    # Spotify
    BuildArtistSpotifyJob.perform_async(artist_id) if artist.spotify_last_updated_at.blank? || artist.spotify_last_updated_at < days.day.ago

    # Apple Music
    if AppleMusic.token
      BuildArtistApplemusicJob.perform_async(artist_id) if artist.applemusic_last_updated_at.blank? || artist.applemusic_last_updated_at < days.day.ago
    end
    
    # IMVDb
    if ENV['imvdb_key']
      imvdb_days = days * 2
      BuildArtistImvdbJob.perform_async(artist_id) if artist.imvdb_last_updated_at.blank? || artist.imvdb_last_updated_at < imvdb_days.days.ago
    end

    # MusicBrainz
    musicbrainz_days = days * 90
    BuildArtistMusicbrainzJob.perform_async(artist_id) if artist.musicbrainz_last_updated_at.blank? || artist.musicbrainz_last_updated_at < musicbrainz_days.days.ago
  end
end
