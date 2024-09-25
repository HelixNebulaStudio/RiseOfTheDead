local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);

local ToolAnimator = {};
ToolAnimator.__index = ToolAnimator;

local placeholderAnimation = Instance.new("Animation");
placeholderAnimation.AnimationId = "rbxassetid://14884515645";
local placeholderTrack = script.Humanoid:LoadAnimation(placeholderAnimation);
placeholderTrack.Name = "PlaceholderTrack";

function ToolAnimator.new(animator)
    local self = {
        Animator = animator;
        State = "";
        Anims = {};
        StateList = {};
    };

    setmetatable(self, ToolAnimator);
    return self;
end

function ToolAnimator:LoadToolAnimations(toolLibAnimations, setState)
	for key, animLib in pairs(toolLibAnimations) do
        local animPacket = {};

        for idKey, idList in pairs(animLib) do
            local stateName = "";
            if idKey:sub(1, 2) == "Id" then
                stateName = idKey:sub(3, #idKey);
            else
                continue;
            end

            idList = typeof(idList) == "table" and idList or {idList};

            animPacket[stateName] = {};
            table.insert(self.StateList, stateName);

            for a=1, #idList do
                if typeof(idList[a]) ~= "number" then continue end;
                local animationId = "rbxassetid://"..idList[a];
                
                local animationFile = Instance.new("Animation");
                animationFile.Name = `{key}:{stateName}`;
                animationFile.AnimationId = animationId;
                animationFile.Parent = self.Animator;

                local track: AnimationTrack = self.Animator:LoadAnimation(animationFile);
                
                if animLib.Looped ~= nil then
                    track.Looped = animLib.Looped == true;
                end
                
                if string.match(key, "Core") == nil then
                    track.Priority = Enum.AnimationPriority.Action2;
                end

                table.insert(animPacket[stateName], track);
            end
        end

        self.Anims[key] = animPacket;
	end;

    if setState then
        self:SetState(setState);
    end
end

function ToolAnimator:Destroy()
    for key, animPacket in pairs(self.Anims) do
        for state, tracks: {AnimationTrack} in pairs(animPacket) do
            for a=1, #tracks do
                tracks[a]:Stop();
            end
            
        end
    end
end

function ToolAnimator:SetState(state)
    self.State = state or "";
end

function ToolAnimator:GetTracks(animKey)
    local animPacket = self.Anims[animKey];
    if animPacket == nil then
        Debugger:Warn(`Missing tool animation ({animKey})`);
        return;
    end

    local availableTracks = animPacket[self.State];
    if availableTracks == nil then
        return;
    end

    return availableTracks;
end

function ToolAnimator:GetPlaying(animKey)
    local animPacket = self.Anims[animKey];
    if animPacket == nil then
        Debugger:Warn(`Missing tool animation ({animKey})`);
        return;
    end

    local availableTracks = animPacket[self.State];
    if availableTracks == nil then
        return;
    end

    for a=1, #availableTracks do
        if availableTracks[a].IsPlaying then
            return availableTracks[a];
        end
    end

    return;
end

function ToolAnimator:Play(animKey, param)
    param = param or {};

    -- optional params
    local fadeTime = param.FadeTime or nil;
    local playSpeed = param.PlaySpeed or nil;
    local playLength = param.PlayLength or nil;

    local activeState = self.State;

    local animPacket = self.Anims[animKey];
    if animPacket == nil then
        Debugger:Warn(`Missing tool animation ({animKey})`);
        return placeholderTrack;
    end

    local availableTracks = animPacket[activeState];
    if availableTracks == nil then
        Debugger:Warn(`Missing tool animation tracks ({animKey}:{activeState})`);
        return placeholderTrack;
    end

    local selectedTrack;
    for state, tracks: {AnimationTrack} in pairs(animPacket) do
        if state == activeState then
            selectedTrack = tracks[math.random(1, #tracks)];
            selectedTrack:Play(fadeTime);
            if playSpeed then
                selectedTrack:AdjustSpeed(playSpeed);
            elseif playLength and selectedTrack.Length > 0 then
                selectedTrack:AdjustSpeed(selectedTrack.Length/playLength);
            end

            for a=1, #tracks do
                if tracks[a] ~= selectedTrack then
                    tracks[a]:Stop();
                end
            end

        else
            for a=1, #tracks do
                tracks[a]:Stop();
            end

        end
    end

    return selectedTrack or placeholderTrack;
end

function ToolAnimator:Stop(animKey, param)
    param = param or {};
    
    -- optional params
    local fadeTime = param.FadeTime or nil;

    local animPacket = self.Anims[animKey];
    if animPacket == nil then
        Debugger:Warn(`Missing tool animation ({animKey})`);
        return;
    end

    for state, tracks: {AnimationTrack} in pairs(animPacket) do
        for a=1, #tracks do
            local track = tracks[a];
            if not track.IsPlaying then continue end;

            if state == self.State then
                track:Stop(fadeTime);
            else
                track:Stop();
            end
        end
    end

end

function ToolAnimator:ConnectMarkerSignal(markerKey, func)
    for animKey, animPacket in pairs(self.Anims) do
        for state, tracks: {AnimationTrack} in pairs(animPacket) do
            for a=1, #tracks do
                local track = tracks[a];
                
                track:GetMarkerReachedSignal(markerKey):Connect(function(value)
                    func(animKey, track, value);
                end)
            end
        end
    end
end

return ToolAnimator;