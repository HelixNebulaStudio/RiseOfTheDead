local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modLogicTree = require(game.ReplicatedStorage.Library.LogicTree);

local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modVector = require(game.ReplicatedStorage.Library.Util.Vector);

local treePackage = {
    Logic = {
        FightSelect={"Or"; "MeleeToolSequence"; "GunToolSequence";};
        IdleTasksSequence={"And"; "IdleTasks";};
        HealSelfSequence={"And"; "SelfHeal";};
        Root={"Or"; "ProcessStatus"; "DefaultStateSelect";};
        DefaultStateSelect={"Or"; "FleeSelect"; "FightSelect"; "AlertSelect"; "IdleSelect";};
        IdleSelect={"Or"; "HealSelfSequence"; "HealNearbySequence"; "IdleTasksSequence"; "PatrolSequence";};
        EquipSequence={"And"; "EquipWeapon";};
        InvestigateNoiseSequence={"And"; "InvestigateNoise";};
        HideSequence={"And"; "HasEnemy"; "IsCoward"; "HideAway";};
        FleeSelect={"Or"; "HideSequence";};
        MeleeToolSequence={"And"; "SwingMelee";};
        AlertSelect={"Or"; "EquipSequence"; "InvestigateNoiseSequence";};
        GunToolSequence={"And"; "FireGun";};
        PatrolSequence={"And"; "Patrol";};
        HealNearbySequence={"And"; "HealAlly";};
    };
};

function treePackage.HasEnemy(logic, npcClass: NpcClass)
    local targetHandler: NpcTargetHandler = npcClass:GetComponent("TargetHandler");
    return targetHandler.EnemyClass ~= nil and logic.Success or logic.Failure;
end

function treePackage.IsCoward(logic, npcClass: NpcClass)
    local properties = npcClass.Properties;
    if properties.IsCoward == nil then
        properties.IsCoward = math.random(1, 100) <= 20;
    end

    return properties.IsCoward and logic.Success or logic.Failure;
end

function treePackage.HideAway(logic, npcClass: NpcClass)
    local shouldHide = false;

    local healthComp: HealthComp = npcClass.HealthComp;
    if healthComp.CurHealth >= healthComp.MaxHealth * 0.1 then
        shouldHide = true;
    end;
    
    local wieldComp: WieldComp = npcClass.WieldComp;
    if wieldComp.ItemId == nil then
        shouldHide = true;
    end;
    
    if not shouldHide then return end;

    -- TODO: Implement hide away;
    return logic.Success;
end

function treePackage.SwingMelee(logic, npcClass: NpcClass)
    local wieldComp: WieldComp = npcClass.WieldComp;
    if wieldComp.EquipmentClass == nil or wieldComp.EquipmentClass.Package.HandlerType ~= "MeleeTool" then return end;

    -- TODO: Implement swing melee;
    return logic.Success;
end

function treePackage.FireGun(logic, npcClass: NpcClass)
    local wieldComp: WieldComp = npcClass.WieldComp;
    if wieldComp.EquipmentClass == nil or wieldComp.EquipmentClass.Package.HandlerType ~= "GunTool" then return end;
   
    

    return logic.Success;
end

function treePackage.EquipWeapon(logic, npcClass: NpcClass)
    local properties = npcClass.Properties;
    local wieldComp: WieldComp = npcClass.WieldComp;

    if wieldComp.ItemId ~= nil then return end;
    if properties.WeaponId == nil then return end;

    wieldComp:Equip{
        ItemId = properties.WeaponId;
        OnSuccessFunc = function()
            local equipmentClass: EquipmentClass? = wieldComp.EquipmentClass;
            if equipmentClass == nil then return end;

            equipmentClass.Configurations.BaseValues["Damage"] = properties.AttackDamage;

            -- if self.Properties.WeaponId == "ak47" then
            -- 	local akSkin = [[{"Plans":{"StockGrip":";;100;,,,,,;;;;;","[All]":";;;,,,,,;;;;;","Stock":";;100;,,,,,;;;;;"},"Layers":[]}]];
            -- 	self.Wield.SetCustomization(akSkin);
            -- end
        end;
    };

    return logic.Success;
end

return treePackage;

---@tree {"version":"0.3.0","scope":"tree","id":"2d2f9c4c-bb58-4a61-991f-f20d8a59c218","title":"BanditTree","description":"","root":"807cea1e-1b71-4db7-8f13-d37ff86e8898","properties":{},"nodes":{"807cea1e-1b71-4db7-8f13-d37ff86e8898":{"id":"807cea1e-1b71-4db7-8f13-d37ff86e8898","name":"select","title":"Root","description":"","properties":{},"display":{"x":-396,"y":-108},"children":["8618c36d-9aa4-4d1d-8656-f5a03f60b412","98dd7b86-5dae-4552-8029-b3e3a3cee185"]},"8618c36d-9aa4-4d1d-8656-f5a03f60b412":{"id":"8618c36d-9aa4-4d1d-8656-f5a03f60b412","name":"log","title":"ProcessStatus","description":"","properties":{},"display":{"x":-192,"y":-288}},"98dd7b86-5dae-4552-8029-b3e3a3cee185":{"id":"98dd7b86-5dae-4552-8029-b3e3a3cee185","name":"select","title":"DefaultStateSelect","description":"","properties":{},"display":{"x":-192,"y":60},"children":["ecb43531-d583-4dc5-9e20-f91e15f69089","3d42da56-59e5-4ef4-8fb7-ee30d946623c","38890bd9-2355-463c-8f8f-da0af04dbe39","56850b4a-8bd3-4cd6-80f0-877b88554e44"]},"3d42da56-59e5-4ef4-8fb7-ee30d946623c":{"id":"3d42da56-59e5-4ef4-8fb7-ee30d946623c","name":"select","title":"FightSelect","description":"","properties":{},"display":{"x":24,"y":-60},"children":["66ed3c8f-29b4-4dd0-a07c-ee8895cbf6bb","82c23dc1-bc96-46ae-b51e-257da48888ea"]},"ecb43531-d583-4dc5-9e20-f91e15f69089":{"id":"ecb43531-d583-4dc5-9e20-f91e15f69089","name":"select","title":"FleeSelect","description":"","properties":{},"display":{"x":24,"y":-192},"children":["58109a47-466d-4763-beb5-3e4f4f429cd5"]},"82c23dc1-bc96-46ae-b51e-257da48888ea":{"id":"82c23dc1-bc96-46ae-b51e-257da48888ea","name":"sequence","title":"GunToolSequence","description":"","properties":{},"display":{"x":228,"y":-24},"children":["87252cfb-feef-43de-9ce7-9a6765a22c96"]},"87252cfb-feef-43de-9ce7-9a6765a22c96":{"id":"87252cfb-feef-43de-9ce7-9a6765a22c96","name":"log","title":"FireGun","description":"","properties":{},"display":{"x":432,"y":-24}},"58adc976-689d-4e77-9315-0892def10877":{"id":"58adc976-689d-4e77-9315-0892def10877","name":"log","title":"SwingMelee","description":"","properties":{},"display":{"x":432,"y":-108}},"66ed3c8f-29b4-4dd0-a07c-ee8895cbf6bb":{"id":"66ed3c8f-29b4-4dd0-a07c-ee8895cbf6bb","name":"sequence","title":"MeleeToolSequence","description":"","properties":{},"display":{"x":228,"y":-108},"children":["58adc976-689d-4e77-9315-0892def10877"]},"58109a47-466d-4763-beb5-3e4f4f429cd5":{"id":"58109a47-466d-4763-beb5-3e4f4f429cd5","name":"sequence","title":"HideSequence","description":"","properties":{},"display":{"x":228,"y":-192},"children":["798a504e-5325-4711-b0e9-f368babd9b0a"]},"798a504e-5325-4711-b0e9-f368babd9b0a":{"id":"798a504e-5325-4711-b0e9-f368babd9b0a","name":"log","title":"HideAway","description":"","properties":{},"display":{"x":432,"y":-192}},"38890bd9-2355-463c-8f8f-da0af04dbe39":{"id":"38890bd9-2355-463c-8f8f-da0af04dbe39","name":"select","title":"AlertSelect","description":"","properties":{},"display":{"x":24,"y":108},"children":["ba7939dd-e134-4112-92f2-804617b63970","9ad843a8-8bed-4809-8fa6-77addd8c6a9a"]},"ba7939dd-e134-4112-92f2-804617b63970":{"id":"ba7939dd-e134-4112-92f2-804617b63970","name":"sequence","title":"EquipSequence","description":"","properties":{},"display":{"x":228,"y":72},"children":["f379d89d-9285-4331-8fd9-810a1b257572"]},"f379d89d-9285-4331-8fd9-810a1b257572":{"id":"f379d89d-9285-4331-8fd9-810a1b257572","name":"log","title":"EquipWeapon","description":"","properties":{},"display":{"x":432,"y":72}},"9ad843a8-8bed-4809-8fa6-77addd8c6a9a":{"id":"9ad843a8-8bed-4809-8fa6-77addd8c6a9a","name":"sequence","title":"InvestigateNoiseSequence","description":"","properties":{},"display":{"x":228,"y":156},"children":["5f84837c-4595-4f5c-b220-cb397f27456a"]},"5f84837c-4595-4f5c-b220-cb397f27456a":{"id":"5f84837c-4595-4f5c-b220-cb397f27456a","name":"log","title":"InvestigateNoise","description":"","properties":{},"display":{"x":432,"y":156}},"56850b4a-8bd3-4cd6-80f0-877b88554e44":{"id":"56850b4a-8bd3-4cd6-80f0-877b88554e44","name":"select","title":"IdleSelect","description":"","properties":{},"display":{"x":24,"y":372},"children":["809878b0-d22f-472c-944f-844247e94946","cf98c8b0-b467-4793-9392-8c4a9c3911f1","f3c5d566-6736-4a2e-be9f-e0a756000f8b","cee37021-6874-4552-9ce0-3c94e0743ec1"]},"809878b0-d22f-472c-944f-844247e94946":{"id":"809878b0-d22f-472c-944f-844247e94946","name":"sequence","title":"HealSelfSequence","description":"","properties":{},"display":{"x":228,"y":240},"children":["173460ee-fb97-49d0-a902-7818c8b3d942"]},"173460ee-fb97-49d0-a902-7818c8b3d942":{"id":"173460ee-fb97-49d0-a902-7818c8b3d942","name":"log","title":"SelfHeal","description":"","properties":{},"display":{"x":432,"y":240}},"cf98c8b0-b467-4793-9392-8c4a9c3911f1":{"id":"cf98c8b0-b467-4793-9392-8c4a9c3911f1","name":"sequence","title":"HealNearbySequence","description":"","properties":{},"display":{"x":228,"y":336},"children":["cfe491f2-33d5-411c-8a1b-99d049deab0d"]},"cfe491f2-33d5-411c-8a1b-99d049deab0d":{"id":"cfe491f2-33d5-411c-8a1b-99d049deab0d","name":"log","title":"HealAlly","description":"","properties":{},"display":{"x":432,"y":336}},"f3c5d566-6736-4a2e-be9f-e0a756000f8b":{"id":"f3c5d566-6736-4a2e-be9f-e0a756000f8b","name":"sequence","title":"IdleTasksSequence","description":"","properties":{},"display":{"x":228,"y":420},"children":["0ffb6e42-cdcd-4bf2-ba43-1daaaef80c18"]},"0ffb6e42-cdcd-4bf2-ba43-1daaaef80c18":{"id":"0ffb6e42-cdcd-4bf2-ba43-1daaaef80c18","name":"log","title":"IdleTasks","description":"","properties":{},"display":{"x":432,"y":420}},"cee37021-6874-4552-9ce0-3c94e0743ec1":{"id":"cee37021-6874-4552-9ce0-3c94e0743ec1","name":"sequence","title":"PatrolSequence","description":"","properties":{},"display":{"x":228,"y":504},"children":["5bba86d1-73ce-4010-b995-242aa9f01f3f"]},"5bba86d1-73ce-4010-b995-242aa9f01f3f":{"id":"5bba86d1-73ce-4010-b995-242aa9f01f3f","name":"log","title":"Patrol","description":"","properties":{},"display":{"x":432,"y":504}}},"display":{"camera_x":899,"camera_y":394.5,"camera_z":0.75,"x":-600,"y":-108},"custom_nodes":[{"version":"0.3.0","scope":"node","properties":{}}]}
