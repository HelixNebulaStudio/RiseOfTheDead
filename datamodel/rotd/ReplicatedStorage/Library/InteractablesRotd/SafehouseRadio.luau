local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local TweenService = game:GetService("TweenService");

local modMath = require(game.ReplicatedStorage.Library.Util.Math);

local songs = {
	{Name="Rave"; Id="rbxassetid://1846368080", v=0.5, p=1};
	{Name="Activity"; Id="rbxassetid://1842306658", v=0.5, p=1};
	{Name="Wonderful Day"; Id="rbxassetid://1843382633", v=0.5, p=1};
	{Name="Meltdown"; Id="rbxassetid://1845092181", v=0.5, p=1};
	{Name="UpTown"; Id="rbxassetid://1845554017", v=0.5, p=1};
	{Name="Hardstyle"; Id="rbxassetid://1839246774", v=0.5, p=1};
	{Name="On The Beach"; Id="rbxassetid://1845891180", v=0.5, p=1};
}
local randomColors = {
	Color3.fromRGB(255, 0, 0),
	Color3.fromRGB(0, 255, 255),
	Color3.fromRGB(0, 255, 0),
	Color3.fromRGB(255, 255, 0),
	Color3.fromRGB(0, 0, 255),
	Color3.fromRGB(255, 0, 255)
}

local interactablePackage = {};

function interactablePackage.init(super) -- Server/Client
    local SafehouseRadio = super.newPackage{
		Name = "SafehouseRadio";
        Type = "ButtonRotd";
    };

	local lightSources = {};
	local lastsong = nil;

    function SafehouseRadio.new(interactable: InteractableInstance)
        local config: Configuration = interactable.Config;
        config:SetAttribute("_Toggle", "IsActive");

        if RunService:IsServer() then
            local interactPoint = Instance.new("Attachment");
            interactPoint.Name = `InteractPoint`;
            interactPoint.Parent = config;
            interactPoint.CFrame = CFrame.new(-1, 0, 0);

            local sound = Instance.new("Sound");
            sound.Name = `Loop`;
            sound.RollOffMaxDistance = 70;
            sound.RollOffMinDistance = 35;
            sound.RollOffMode = Enum.RollOffMode.Linear;
            sound.Volume = 0.5;
            sound.Looped = true;
            sound.SoundGroup = game.SoundService:FindFirstChild("BackgroundMusic");
            sound.Parent = interactPoint;

            interactable.Values.LoopSound = sound;
        end

        interactable.Values.IsActive = false;
        
        local interactPart = interactable.Part;
        local radioLightPart = interactPart.Parent and interactPart.Parent:FindFirstChild("_lightSource", true) or nil;
        if radioLightPart then
            interactable.Values.RadioLightPart = radioLightPart;
            if radioLightPart:FindFirstChild("PointLight") then
                interactable.Values.RadioPointLight = radioLightPart.PointLight;
            end
        end

        local radioPointLight = interactable.Values.RadioPointLight;
        if radioLightPart and radioPointLight then

            table.insert(lightSources, {
                Source = radioLightPart; 
                OriginalColor = radioLightPart.Color; 
                LightObjects = {
                    {
                        Light = radioPointLight; 
                        OriginalColor = radioPointLight.Color;
                    };
                }
            });
        end
    end

    function SafehouseRadio.BindInteract(interactable: InteractableInstance, info: InteractInfo)
        local config = interactable.Config;
        SafehouseRadio.TypePackage.BindInteract(interactable, info);
        if info.Action == "Client" then return end;

		local pickSong = songs[math.random(#songs)];
		repeat
			pickSong = songs[math.random(#songs)];
			task.wait();
		until pickSong ~= lastsong;
		lastsong = pickSong;
		
		local trackName = pickSong.Name;
		
		local players = game.Players:GetPlayers();
		shared.Notify(players, '<b><font size="16">Radio</font></b>: Play Track ('..trackName..')', "Message");


        local radioLightPart = interactable.Values.RadioLightPart;
        if radioLightPart then
		    radioLightPart.Transparency = 0;
        end
        local radioPointLight = interactable.Values.RadioPointLight;
        if radioPointLight then
            radioPointLight.Enabled = true;
        end

        local radioSound = interactable.Values.LoopSound;
		radioSound.SoundId = pickSong.Id;		
		radioSound:Play()

        task.spawn(function()
            local discoTick = tick();
            task.wait(1);

            while radioSound.IsPlaying do
                task.wait(1/30);
                    
                local loudness = modMath.MapNum(radioSound.PlaybackLoudness, 0, 1000, 12, 24);
                
                if radioLightPart then
                    radioLightPart.Size = Vector3.new(1,1,1) * (1+loudness) * radioSound.Volume;
                end
                if radioPointLight then
                    radioPointLight.Range = 8 + (loudness/4);
                end

                if tick() < discoTick then continue end;
                discoTick = tick()+1;

                for a=1, #lightSources do
                    local newColor = randomColors[math.random(1, #randomColors)];
                    local tween = TweenService:Create(
                        lightSources[a].Source, 
                        TweenInfo.new(math.random(50, 99)/100), 
                        {Color=newColor}
                    );
                    for b=1, #lightSources[a].LightObjects do
                        local lightTween = TweenService:Create(
                            lightSources[a].LightObjects[b].Light, 
                            TweenInfo.new(math.random(50, 99)/100), 
                            {Color=newColor}
                        );
                        lightTween:Play();
                    end
                    tween:Play();
                end
            end

            local resetTime = 5;
            for a=1, #lightSources do
                local tween = TweenService:Create(
                    lightSources[a].Source, 
                    TweenInfo.new(resetTime), 
                    {Color=lightSources[a].OriginalColor}
                );
                for b=1, #lightSources[a].LightObjects do
                    local lightTween = TweenService:Create(
                        lightSources[a].LightObjects[b].Light, 
                        TweenInfo.new(resetTime), 
                        {Color=lightSources[a].LightObjects[b].OriginalColor}
                    );
                    lightTween:Play();
                end
                tween:Play();
            end
        end)

		
		radioSound.Volume = pickSong.v;
		radioSound.PlaybackSpeed = pickSong.p;

		local length = 110;
		task.wait(length);
		repeat
			radioSound.Volume = radioSound.Volume -((1/30)/5);
			task.wait(1/30);
		until radioSound.Volume <= 0;
		radioSound:Stop();
		
        if radioLightPart then
		    radioLightPart.Size = Vector3.new(1, 1, 1);
		    radioLightPart.Transparency = 1;
        end
        if radioPointLight then
            radioPointLight.Enabled = false;
        end

        task.wait(30);
        config:SetAttribute("IsActive", false);

        return;
    end
    
    function SafehouseRadio.BindPrompt(interactable: InteractableInstance, info: InteractInfo)
        local config = interactable.Config;
        if interactable.Values.IsActive then
            interactable.Label = `Playing`;
            interactable.CanInteract = false;

        else
            interactable.Label = `Play Radio`;
            interactable.CanInteract = true;

        end
    end

    super.registerPackage(SafehouseRadio);
end

return interactablePackage;

