local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--
local PageInterface = {};
PageInterface.__index = PageInterface;

local localplayer = game.Players.LocalPlayer;

local TextService = game:GetService("TextService");
local HttpService = game:GetService("HttpService");

local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modItemsLibrary = require(game.ReplicatedStorage.Library.ItemsLibrary);
local modRemotesManager = require(game.ReplicatedStorage.Library:WaitForChild("RemotesManager"));
local modRewardsLibrary = require(game.ReplicatedStorage.Library.RewardsLibrary);
local modCrateLibrary = require(game.ReplicatedStorage.Library.CrateLibrary);
local modGameModeLibrary = require(game.ReplicatedStorage.Library.GameModeLibrary);

local modItemInterface = require(game.ReplicatedStorage.Library.UI.ItemInterface);
local modRichFormatter = require(game.ReplicatedStorage.Library.UI.RichFormatter);

local remoteShopService = modRemotesManager:Get("ShopService");

local catelogPage = script:WaitForChild("CatalogPage");
local listTemplate = script:WaitForChild("listTemplate");
local tabTemplate = script:WaitForChild("tabTemplate");

local organizedItemsList;
local itemToolTip;

local isDevBranch = modBranchConfigs.CurrentBranch.Name == "Dev";

local catInfoLib = {
	Resource={Order=10; Title="Resources";};
	Gun={Order=20; Title="Guns";};
	Melee={Order=30; Title="Melees";};
	Throwable={Order=40; Title="Throwables";};
	
	--== Clothing
	--Clothing={Order=50;};
	["Head"]={Order=51; Title="Head";};
	["Chest"]={Order=52; Title="Chest";};
	--["Legs"]={Order=53; Title="Legs";};
	["Gloves"]={Order=54; Title="Gloves";};
	["Shoes"]={Order=55; Title="Shoes";};
	["Utility Wear"]={Order=56; Title="Utility Wear";};
	
	
	--== Mods
	--Mod={Order=51; Title="Mods";};
	["Damage Mods"]={Order=71; Title="Damage Mods";};
	["Fire Rate Mods"]={Order=72; Title="Fire Rate Mods";};
	["Reload Speed Mods"]={Order=73; Title="Reload Speed Mods";};
	["Ammo Capacity Mods"]={Order=74; Title="Ammo Capacity Mods";};

	["Armor Mods"]={Order=75; Title="Armor Mods";};
	["Health Mods"]={Order=76; Title="Health Mods";};
	
	["Elemental Mods"]={Order=77; Title="Elemental Mods";};
	["Rare Mods"]={Order=78; Title="Rare Mods";};
	--
	
	Storage={Order=100;};
	Crate={Order=110; Title="Crates";};
	Component={Order=120; Title="Components";};
	Commodity={Order=130; Title="Commodities";};
	Food={Order=140; Title="Food";};

	Map={Order=150; Title="Maps";};

	Summon={Order=160; Title="Summons";};
	Key={Order=170; Title="Keys";};
	
	Instrument={Order=180; Title="Instruments";};
	Blueprint={Order=190; Title="Blueprints";};
	Mission={Order=200; Title="Mission";};
	
	Tool={Order=210; Title="Tools";};
	Deployable={Order=220; Title="Deployables";};
	
	["Item Unlockable"]={Order=230; Title="Item Customization Unlockables";};
	["Skin Perm"]={Order=240; Title="Skin Permanents";};
	["Color Pack"]={Order=250; Title="Color Customization Packs";};
	["Skin Pack"]={Order=260; Title="Skin Customization Packs";};
	["Misc Usable"]={Order=270; Title="Misc Usables";};
	
	
	["April Fools"]={Order=280;};
	["Easter"]={Order=290;};
	["Summer"]={Order=300;};
	["Slaughterfest"]={Order=310;};
	["Frostivus"]={Order=320;};

	["Unobtainable"]=(isDevBranch and {Order=500; Title="[Dev Branch] Unobtainable";} or nil);
	["Dev"]=(isDevBranch and {Order=999; Title="[Dev Branch] Developer Tools";} or nil);
}

local itemDetailCache = {};
--==

function PageInterface:Load(interface)
	if organizedItemsList == nil then
		organizedItemsList = {};
		
		local indexedList = modItemsLibrary.Library:GetIndexList();
		for i=1, #indexedList do
			local itemLib = indexedList[i];
			local itemId = itemLib.Id;

			local tags = itemLib.Tags;
			
			if table.find(tags, "HideFromCodex") then
				continue;
			end
			
			for a=1, #tags do
				if catInfoLib[tags[a]] then
					table.insert(organizedItemsList, {
						ItemLib=itemLib;
						Tag=tags[a];
						Unobtainable=table.find(tags, "Unobtainable") ~= nil;
					});
				end
			end
		end
	end

	if itemToolTip then itemToolTip:Destroy(); end
	itemToolTip = modItemInterface.newItemTooltip();
	
	local modData = require(localplayer:WaitForChild("DataModule"));
	local itemCodexPacket = modData:GetFlag("ItemCodex");
	local itemUnlockFlag = itemCodexPacket and itemCodexPacket.Data or {};
	
	local frame = catelogPage:Clone();
	local typeCategory = {};
	
	for a=1, #organizedItemsList do
		local itemLib = organizedItemsList[a].ItemLib;
		local itemTag = organizedItemsList[a].Tag;
		local itemIsUnobtainable = organizedItemsList[a].Unobtainable;
		
		if isDevBranch then
			itemIsUnobtainable = false;
		end
		
		local typeInfo = catInfoLib[itemTag];
		local catInfo = typeCategory[itemTag];
		
		local newTab, newList;
		if catInfo == nil and typeInfo then
			newTab = tabTemplate:Clone();
			local titleLabel = newTab:WaitForChild("titleLabel");
			local semiCollapseSign = newTab:WaitForChild("semiCollapseSign");
			local collapseSign = newTab:WaitForChild("collapseSign");
			local expandSign = newTab:WaitForChild("expandSign");
			
			titleLabel.Text = typeInfo.Title or itemTag;
			
			newTab.LayoutOrder = typeInfo.Order;
			newTab.Parent = frame;
			
			newList = listTemplate:Clone();
			newList.LayoutOrder = typeInfo.Order+0.5;
			newList.Parent = frame;
			
			catInfo = {
				Tab=newTab;
				List=newList;
			}
			typeCategory[itemTag] = catInfo;
		end
		
		local itemUnlocked = isDevBranch or itemUnlockFlag[itemLib.Id];
		if itemUnlocked then
			itemIsUnobtainable = false;
		end
		
		if catInfo and itemIsUnobtainable == false then
			local itemButtonObj = modItemInterface.newItemButton(itemLib.Id, true);
			local newItemButton = itemButtonObj.ImageButton;
			newItemButton.LayoutOrder = a;
			newItemButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30);
			newItemButton.BackgroundTransparency = 0.2;
			
			itemButtonObj:Update();
			
			local unlocked, showLockedInfo;
			
			if itemUnlocked then
				unlocked = true;
				showLockedInfo = false;
				
			else
				unlocked = false;
				showLockedInfo = true;
				newItemButton.ImageColor3 = Color3.fromRGB(0, 0, 0);
				
			end
			
			local function updateTooltip()
				itemToolTip.Frame.Parent = interface.PageFrame.Parent;

				if unlocked and showLockedInfo == false then
					itemToolTip.CustomUpdate = nil;

				else
					function itemToolTip:CustomUpdate(itemId)
						local itemLib = modItemsLibrary:Find(itemId);
						if itemLib == nil then return end;

						local modData = require(localplayer:WaitForChild("DataModule"));

						local defaultFrame = self.Frame:WaitForChild("default");
						local nameTag = self.Frame:WaitForChild("NameTag");
						local itemIcon = defaultFrame:WaitForChild("Icon");
						local quantityLabel = defaultFrame:WaitForChild("QuantityLabel");
						local typeIcon = defaultFrame:WaitForChild("TypeIcon");
						local descLabel = defaultFrame:WaitForChild("Description");

						defaultFrame.Visible = true;

						nameTag.Text = itemLib.Name;
						itemIcon.Visible = false;
						typeIcon.Image = itemLib.TypeIcon or modItemsLibrary.TypeIcons[itemLib.Type] or "";
						quantityLabel.Text = "";

						if itemDetailCache[itemId] == nil then
							task.spawn(function()
								local r = remoteShopService:InvokeServer("iteminfo", itemId);
								if r and typeof(r) == "table" then
									itemDetailCache[itemId] = r;
									updateTooltip();
								end
							end)
							return;
						end
						local itemDetails = itemDetailCache[itemId];

						local descText = ""
						if not unlocked then
							descText = descText.."<b>You have not yet unlocked this item.</b>\n\n\n";
						end

						descText = descText..modItemInterface.Headers.H3O.."Description:"..modItemInterface.Headers.H3C.."\n"..(itemLib.Description or "Missing description").."\n";

						if itemDetails and typeof(itemDetails) == "table" then
							descText = descText.. modItemInterface.Headers.H3O.. "\nSources:"..modItemInterface.Headers.H3C.."\n"
							
							local obtainable = false;
							if itemLib.Sources then
								for a=1, #itemLib.Sources do
									descText = descText.. "  • "..itemLib.Sources[a].."\n";
									obtainable = true;
								end
							end
							
							local srcTable = itemDetails.SourceTable;
							if srcTable and next(srcTable) ~= nil then
								obtainable = true;
								if srcTable.RewardSrcs then
									for a=1, #srcTable.RewardSrcs do
										local rewardData = srcTable.RewardSrcs[a];
										
										if rewardData.GameMode then
											descText = descText.. "  • Dropped in <b>"..rewardData.GameMode..": "..rewardData.StageName.."</b>".."\n";
											
										elseif rewardData.CrateId then
											local crateLib = modCrateLibrary.Get(rewardData.CrateId)
											descText = descText.. "  • Dropped from <b>"..crateLib.Name.."</b>".."\n";

										elseif rewardData.RewardId then
											local rewardLib = modRewardsLibrary:Find(rewardData.RewardId);
											descText = descText.. "  • Dropped from <b>".. (rewardLib.Name or rewardLib.Id) .."</b>".."\n";

										end
									end
								end
								
								if srcTable.Blueprint then
									local bpItemLib = modItemsLibrary:Find(srcTable.Blueprint);
									descText = descText.. "  • Built with <b>"..bpItemLib.Name.."</b>\n";
								end

								if srcTable.RatShop then
									if srcTable.RatShop.Currency == "Money" then
										descText = descText.. "  • Purchasable from <b>RAT Shop: $"..srcTable.RatShop.Price.. (srcTable.RatShop.PremiumOnly and modRichFormatter.ColorPremiumText(" (Premium Only)") or "").."</b>\n";
									else
										descText = descText.. "  • Purchasable from <b>RAT Shop: "..srcTable.RatShop.Price.." "..srcTable.RatShop.Currency.. (srcTable.RatShop.PremiumOnly and modRichFormatter.ColorPremiumText(" (Premium Only)") or "").."</b>\n";
									end
								end

								if srcTable.GoldShop then
									if srcTable.GoldShop.Type == "ThirdParty" then
										descText = descText.. "  • Purchasable from the <b>Gold Shop: "..modRichFormatter.ColorRobuxText("Robux").."</b>\n";

									else
										descText = descText.. "  • Purchasable from the <b>Gold Shop: "..modRichFormatter.ColorPremiumText((srcTable.GoldShop.Price or "?").." Gold").."</b>\n";

									end
									
								end

								if srcTable.Trader then
									descText = descText.. "  • "..srcTable.Trader.."\n";
								end
								if srcTable.MysteryChest then
									descText = descText.. "  • "..srcTable.MysteryChest.."\n";
								end
							else
								if not obtainable then
									descText = descText.. "No way to obtain this item at the moment.";
								end
							end
						end
						
						if itemLib.Tags then
							descText = descText.. modItemInterface.Headers.H3O.. "\nTags: "..modItemInterface.Headers.H3C.."\n"
							descText = descText.. modRichFormatter.RichFontSize("[".. 
								table.concat(itemLib.Tags, ", ")..", ".. 
								itemLib.Id .."]", 12);
						end

						descLabel.Text = descText;
						
						local textbounds = TextService:GetTextSize(descLabel.Text, 
							descLabel.TextSize, 
							descLabel.Font, 
							Vector2.new(300, 1000));

						itemToolTip.Frame.Size = UDim2.new(0, 340, 0, textbounds.Y + 125);	
					end
					
				end

				
				itemToolTip:Update(itemLib.Id);
				itemToolTip:SetPosition(newItemButton);
			end
			
			newItemButton.MouseButton1Click:Connect(function()
				if itemUnlocked then
					showLockedInfo = not showLockedInfo;
				end
				updateTooltip();
			end)
			
			itemToolTip:BindHoverOver(newItemButton, updateTooltip);
			
			newItemButton.Parent = catInfo.List;
		end
		
	end
	
	frame.Parent = interface.PageFrame;
end

return PageInterface;