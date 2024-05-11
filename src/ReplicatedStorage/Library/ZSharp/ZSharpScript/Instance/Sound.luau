return {
    Class={
        SoundId = "";
        Volume = 0.5;
        PlaybackSpeed = 1;
        
        Play = function(instance: Sound)
            instance:Play();
        end;
        Stop = function(instance: Sound)
            instance:Stop();
        end;
    };

    Link=function(zss, sound: Sound)
        if sound == nil then
            sound = Instance.new("Sound");
        end
        return sound;
    end;
}