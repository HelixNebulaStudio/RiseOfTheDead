local RunService = game:GetService("RunService");
local modStatusClass = require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
local modItemsLibrary = require(game.ReplicatedStorage.Library.ItemsLibrary);
--==
local statusPackage = {
    Id="PacifistsAmulet";
    Icon="rbxassetid://16049397225";
    Name="Pacifist's Amulet";
    Description="Armor over charges and increased armor rate from pacifism.";
    Buff=true;
};

function statusPackage:OnExpire()
    if RunService:IsClient() then return end;
    local playerClass = self.PlayerClass;
    if playerClass == nil then return end;
    
    local statusId = self.Id;

    local aoSrcs = playerClass.Properties.ArmorOverchargeSources;
    aoSrcs[statusId] = nil;
    
    playerClass:SetArmorSource(statusId);
end

function statusPackage:OnTick(tickPack)
    if RunService:IsClient() then return end;
    if tickPack.ms100 ~= true then return end;
    local playerClass = self.PlayerClass;
    if playerClass == nil then return end;

    local statusId = self.Id;
    local sync = false;

    local maxAddAp = self.AddAp;
    local addAr = self.AddAr;

    if playerClass.Properties.WarmongerScales then -- disable if warmonger present;
        maxAddAp = 0;
    end

    local aoSrcs = playerClass.Properties.ArmorOverchargeSources;
    
    self.Ap = (self.Ap or 0);
    
    if maxAddAp > 0 then
        local equippedTools = playerClass:GetEquippedTools();
        local itemId = equippedTools and equippedTools.ItemId;
        local isPacifist = (itemId and (modItemsLibrary:HasTag(itemId, "Heal") or modItemsLibrary:HasTag(itemId, "Food")))

        local armorRate = playerClass.Properties.ArmorRate;
        if isPacifist then
            local maxArmor = playerClass.Properties.BaseMaxArmor + (playerClass:GetBodyEquipment("ModArmorPoints") or 0);
            self.Ap = math.clamp(self.Ap + armorRate, 0, maxAddAp);
            
        else
            self.Ap = math.clamp(self.Ap - 0.2, 0, maxAddAp); -- 2 per sec
            
        end
        
        if self.Ap > 0 then
            
            aoSrcs[statusId] = self.Ap;
            playerClass:SetArmorSource(statusId, {
                Amount=addAr/10;
            });
            if not self.Visible then
                self.Visible = true;
                sync = true;
            end
            
        else
            aoSrcs[statusId] = nil;
            playerClass:SetArmorSource(statusId);
            if self.Visible then
                self.Visible = false;
                sync = true;
            end
            
        end
        
    else
        aoSrcs[statusId] = nil;
        playerClass:SetArmorSource(statusId);
        if self.Visible then
            self.Visible = false;
            sync = true;
        end
        
    end
    
    return sync;
end

return modStatusClass.new(statusPackage);