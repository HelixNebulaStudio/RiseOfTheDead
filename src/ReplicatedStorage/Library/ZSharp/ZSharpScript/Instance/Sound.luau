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

	Constructor=function(zss, public, private, instance)
        if private.__instance == nil then
            private.__instance = Instance.new("Sound");
        end
    end;
}