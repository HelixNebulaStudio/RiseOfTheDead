local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);

local npcPackage = {
    Name = "Carlos";
    HumanoidType = "Human";
    
	Configurations = {};
    Properties = {
        PrimaryGunItemId = "m9legacy";
        MeleeItemId = "broomspear";
        Immortal = 1;
    };

    DialogueInteractable = true;

    AddComponents = {
        "TargetHandler";
        "Chat";
        "AttractNpcs";
    };
    AddBehaviorTrees = {
        "SurvivorIdleTree";
        "SurvivorCombatTree";
    };

    Voice = {
        VoiceId = 7;
        Pitch = 0.95;
        Speed = 0.97;
        PlaybackSpeed = 0.96;
    };
    
    SurvivorIdleData = {
        ["Sunday's Safehouse"] = {
            Data = {
                RestFunctionName = "PlayFluteFunc";
                RestTimeInterval = NumberRange.new(120, 300);
                RestingSeatName = "CarlosSeat";
                RestDuration = NumberRange.new(90, 120);
                RestSay = {
                    "The sorrow days will need some tunes..";
                    "♪ You only live once, living miserably around oceans ♪";
                    "I dedicate this to those who did not make it..";
                    "The music of living is over the past.";
                };
            };
            
            sundaysSafehouseStorage = {
                Chance = 1;
                Say = {
                    "*quietly organizing* Just making sure my sheet music is safe..";
                    "*carefully sorting* Need to keep the supplies in harmony..";
                    "*whispers* Hope no one minds me reorganizing a bit..";
                    "Maybe I should leave a note about where things go...";
                    "*arranges items gently* Like arranging notes on a staff...";
                };
                Duration = NumberRange.new(20, 30);
            };
            sundaysShop = {
                Chance = 0.5;
                Say = {
                    "*humming softly* I hope I'm not bothering you, Frank, but I need something...";
                    "*fidgets with flute* Do you... do you ever enjoy music, Frank? Hahah";
                    "*whispers* Maybe I could play something for the shop sometime...";
                };
                Duration = NumberRange.new(30, 34);
            };
            sundaysVendingMachine = {
                Chance = 0.5;
                Say = {
                    "I hope no one minds if I use this..";
                    "*softly taps fingers* Maybe a little treat would help with composing..";
                    "*hums quietly* The machine's hum is almost musical..";
                    "*whispers* Just need something to keep my energy up for practice..";
                };
                InteractSay = {
                    "*carefully picks up $ItemId* Oh... this could be inspiring...";
                    "*whispers* A $ItemId... maybe it'll help with my next composition...";
                    "*gently holds $ItemId* This might set the right mood for practice...";
                    "*quietly* The machine gave me a $ItemId... how interesting...";
                };
                InteractTime = -4;
                Duration = NumberRange.new(14, 20);
            };
        };
    };
};
--==

function npcPackage.Spawned(npcClass: NpcClass)
    local particlesFolder = game.ReplicatedStorage.Particles;
	local musicParticle1 = particlesFolder:WaitForChild("MusicNotes1"):Clone(); 
    musicParticle1.Parent = npcClass.Head;
	local musicParticle2 = particlesFolder:WaitForChild("MusicNotes2"):Clone(); 
    musicParticle2.Parent = npcClass.Head;



	local playFluteCooldown = tick()+20;
    npcClass.Properties.PlayFluteFunc = function()
        task.spawn(function()
            if tick() < playFluteCooldown then return end;
            playFluteCooldown = tick() + math.random(120, 300);

            if npcClass.WieldComp.ItemId ~= "flute" then
                npcClass.WieldComp:Equip{ ItemId = "flute" };
            end
            local toolHandler: ToolHandlerInstance? = npcClass.WieldComp.ToolHandler;
            if toolHandler == nil then return end;

            local mainToolModel = toolHandler.MainToolModel;

            local fluteSong = modAudio.Play("FluteSong"..math.random(1, 2), mainToolModel.PrimaryPart);
            
            if npcClass.WieldComp.ToolHandler and npcClass.WieldComp.ToolHandler.ToolAnimator then
                npcClass.WieldComp.ToolHandler.ToolAnimator:Play("Use");
            end
            
            npcClass:GetComponent("AvatarFace"):Set("rbxassetid://2071837798");

            musicParticle1.Enabled = true;
            musicParticle2.Enabled = true;
            toolHandler.Garbage:Tag(function()
                npcClass:GetComponent("AvatarFace"):Set("rbxassetid://20418584");
                musicParticle1.Enabled = false;
                musicParticle2.Enabled = false;
                
                fluteSong:Destroy();
            end)
            
            task.delay(fluteSong.TimeLength, function()
                if not workspace:IsAncestorOf(mainToolModel) then return end;
                if npcClass.WieldComp.ItemId == "flute" then
                    npcClass.WieldComp:Unequip();
                end
            end)
        end)
    end

end

return npcPackage;