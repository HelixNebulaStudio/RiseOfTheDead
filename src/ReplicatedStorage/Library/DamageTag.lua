local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modSyncTime = require(game.ReplicatedStorage.Library.SyncTime);

--==

local DamageTag = {};
DamageTag.__index = DamageTag;

DamageTag.Tagged = {} :: {[Model]: Tag};
--

local Tag = {};
Tag.__index = Tag;
Tag.ClassName = "Tag";

type TagObject = {
	LastTag: number;
    List: TagList;
}
export type Tag = typeof(setmetatable({} :: TagObject, Tag));

type TagList = {
    [number]:{
        Prefab:Model;
        IsHeadshot:boolean?;
        Player:Player?
    };
}

function Tag.new() : Tag
    local self = {
        LastTag = nil;
        List = {};
    };

    setmetatable(self, Tag);
    return self;
end

function Tag:Add(param)
    self.LastTag = tick();

    local existIndex = nil;

    for a=#self.List, 1, -1 do
        if param.Prefab == self.List[a].Prefab then
            existIndex = a;
            break;
        end
    end

	local player: Player = game.Players:GetPlayerFromCharacter(param.Prefab);
   
    if existIndex then
        self.List[existIndex], self.List[#self.List] = self.List[#self.List], self.List[existIndex];

    else
        table.insert(self.List, param);

    end
end
--

function DamageTag.Tag(victimModel: Model, dealerModel: Model, isHead: boolean?)
	if victimModel == nil then return end;
	if dealerModel == nil then return end;
	
	local parent = victimModel;
	local humanoid = parent:FindFirstChildWhichIsA("Humanoid");
	for a=1, 3 do
		if humanoid == nil then
			parent = parent.Parent;
			if parent == nil then return end;
			
			humanoid = parent:FindFirstChildWhichIsA("Humanoid");
		else
			break;
		end
	end
	
	victimModel = humanoid and humanoid.Parent or nil;
	if victimModel == nil then return end;
	--
    
	local tag = DamageTag.Tagged[victimModel];
	if tag == nil then
        tag = Tag.new();
		DamageTag.Tagged[victimModel] = tag;
	end;
	
    tag:Add{
        Prefab=dealerModel;
        IsHeadshot=isHead;
    };
end

function DamageTag:Get(victimModel: Model, filter: string?) : TagList
	local tag = DamageTag.Tagged[victimModel];
    
    if filter then
        local list: TagList = {};

        for a=1, #tag.List do
            local listItem = tag.List[a];

            if filter == "Player" and listItem.Player then
                table.insert(list, listItem);
            end
        end

        return list;
    end
    return table.clone(tag.List);
end

modSyncTime.GetClock():GetPropertyChangedSignal("Value"):Connect(function()
    for prefab, tag in pairs(DamageTag.Tagged) do
        local cleanUp = false;

        if not workspace:IsAncestorOf(prefab) or prefab.PrimaryPart == nil or not workspace:IsAncestorOf(prefab.PrimaryPart) then
            cleanUp = true;
        elseif tick()-tag.LastTag > 60 then
            cleanUp = true;
        end

        if cleanUp then
            DamageTag.Tagged[prefab] = nil;
        end
    end
end)

return DamageTag;