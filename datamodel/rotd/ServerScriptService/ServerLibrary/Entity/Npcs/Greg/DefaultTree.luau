local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==

local treePackage = {
    LogicString = {
        Default = "SurvivorCombatTree | CutsceneTree | [NpcRoutine]";
        CutsceneTree = "InCutscene & GoTalkWithCaitlinTree | ExitCutscene";
        GoTalkWithCaitlinTree = "ShouldTalkWithCaitlin & (GoToCaitlin & [TalkToCaitlin])"
    };
};

function treePackage.SurvivorCombatTree(npcClass: NpcClass)
    return npcClass.BehaviorTree:RunTree("SurvivorCombatTree", false);
end

function treePackage.InCutscene(npcClass: NpcClass)
    local cutscenePlayersComp = npcClass:GetComponent("CutscenePlayers");
    if cutscenePlayersComp:IsCutsceneActive("87") then
        npcClass.Properties.CutsceneActive = true;
    else
        npcClass.Properties.CutsceneActive = false;
    end

    if npcClass.Properties.CutsceneActive == true then
        npcClass.Properties.LastCutsceneActive = tick();
    end
    return npcClass.Properties.CutsceneActive == true;
end

function treePackage.ExitCutscene(npcClass: NpcClass)
    if npcClass.Properties.LastCutsceneActive == nil then return false; end;

    if tick()-npcClass.Properties.LastCutsceneActive <= 8 then
        npcClass.Move:SetMoveSpeed("set", "walk", 5, npcClass.Move.MoveSpeedPriority.Movement, 8);
        npcClass.Move:MoveTo(Vector3.new(-365.327, 63.046, 202.4));
        return true;
    end

    return false;
end

function treePackage.NpcRoutine(npcClass: NpcClass)
    if game.Lighting:GetAttribute("IsDayTime") == true then
        if npcClass.WieldComp.ItemId == "lantern" then
            npcClass.WieldComp:Unequip();
        end
    else
        if npcClass.WieldComp.ItemId == nil then
            npcClass.WieldComp:Equip{
                ItemId = "lantern";
            };
        end
    end

    return npcClass:GetComponent("NpcRoutine"):Process();
end

function treePackage.Lunch(npcClass: NpcClass)
    local seatPart = workspace.Environment:FindFirstChild(`GregSeat`);
    if seatPart and not npcClass.Humanoid.Sit and npcClass:DistanceFromCharacter(seatPart.Position) <= 10 then
        npcClass:Sit(seatPart);
    end

    local npcRoutineComp = npcClass:GetComponent("NpcRoutine");
    local actionTimeLapse = npcRoutineComp.RoutineActionStartTick and tick()-npcRoutineComp.RoutineActionStartTick or 0;

    if actionTimeLapse >= 38 then
        if npcClass.WieldComp.ItemId == "sandwich" then
            npcClass.WieldComp:Unequip();
        end

    elseif actionTimeLapse >= 8 and npcClass.WieldComp.ItemId == "sandwich" and npcClass.WieldComp.ToolHandler then
		local toolAnimator: ToolAnimator = npcClass.WieldComp.ToolHandler.ToolAnimator;

        if toolAnimator:GetPlaying("Use") == nil then
		    toolAnimator:Play("Use");
        end

    elseif actionTimeLapse >= 5 and npcClass.WieldComp.ItemId == nil then
        npcClass.WieldComp:Equip{
            ItemId = "sandwich";
        };

    end

    return false;
end


--MARK: Interact with Caitlin

function treePackage.ShouldTalkWithCaitlin(npcClass: NpcClass)
    local sleepingStatus = npcClass.StatusComp:GetOrDefault("Sleeping");
    if sleepingStatus then
        npcClass.StatusComp:Apply("Sleeping", nil);
    end;

    return npcClass.Properties.GoTalkWithCaitlin == true;
end

local GREG_CAITLIN_TALK_POS = Vector3.new(-310.98, 63.046, 212.037);
function treePackage.GoToCaitlin(npcClass: NpcClass)
    local caitlinClass = shared.modNpcs.getByModel(workspace.Entity:FindFirstChild("Caitlin"));
    if caitlinClass then
        local dist = npcClass:DistanceFromCharacter(caitlinClass.RootPart.Position);

        if not npcClass.Move:IsAtPosition(GREG_CAITLIN_TALK_POS) then
            npcClass.Move:MoveTo(GREG_CAITLIN_TALK_POS);
        end

        if dist <= 10 then
            return true;
        elseif dist <= 18 then
            npcClass.Move:SetMoveSpeed("set", "walk", 6, npcClass.Move.MoveSpeedPriority.Movement, 2);
            return true;
        elseif dist <= 40 then
            npcClass.Move:SetMoveSpeed("set", "walk", 12, npcClass.Move.MoveSpeedPriority.Movement, 2);
            return true;
        elseif dist <= 100 then
            npcClass.Move:SetMoveSpeed("set", "walk", 20, npcClass.Move.MoveSpeedPriority.Movement, 2);
            return true;
        else
            npcClass:SetCFrame(CFrame.new(GREG_CAITLIN_TALK_POS));
            return false;
        end
    end
    return false;
end

local thingsToSayToCaitlin = {
    "We should really deal with the roaches near the stairwell...";
    "Just moved the boxes to the other side like you said...";
    "I feel like the East fences are getting a bit too overgrown...";
    "We might need to reinforce the South entrance soon...";
};
function treePackage.TalkToCaitlin(npcClass: NpcClass)
    local caitlinClass = shared.modNpcs.getByModel(workspace.Entity:FindFirstChild("Caitlin"));
    if caitlinClass then
        if npcClass.Properties.TalkToCaitlinCooldown and tick() < npcClass.Properties.TalkToCaitlinCooldown then
            return false;
        end
        npcClass.Properties.TalkToCaitlinCooldown = tick() + math.random(10, 60);

        npcClass.Move:HeadTrack(caitlinClass.Head, 3);
        npcClass.Chat(game.Players:GetPlayers(), thingsToSayToCaitlin[math.random(1, #thingsToSayToCaitlin)]);
    end
    return false;
end

return treePackage;