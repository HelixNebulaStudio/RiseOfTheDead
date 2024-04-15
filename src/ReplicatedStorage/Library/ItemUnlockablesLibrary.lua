local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--=
local modLibraryManager = require(game.ReplicatedStorage.Library.LibraryManager);
local particlesFolder = game.ReplicatedStorage:WaitForChild("Particles");

local library = modLibraryManager.new();

function library.UpdateSkin(prefab, skinId)
	local skinLib = library:Find(skinId);
	if skinLib then
		local handle = prefab:FindFirstChild("Handle");
		local jointName = prefab:GetAttribute("ClothingJoint");
		
		if skinLib.SurfaceAppearance and handle then
			if handle:IsDescendantOf(workspace) then -- On Character;
				for _, obj in pairs(handle:GetChildren()) do
					if not obj:IsA("SurfaceAppearance") then continue end;
					obj:Destroy();
				end
				
				local saGroup;
				if skinLib.SurfaceAppearanceParent then
					saGroup = skinLib.SurfaceAppearanceParent:WaitForChild(skinLib.ItemId);
					
				else
					saGroup = script:WaitForChild(skinLib.ItemId);
					
				end
				
				local newSurf = saGroup:WaitForChild(skinId):Clone();
				newSurf.Name = "SurfaceAppearance";
				newSurf.Parent = handle;
				
				
			else -- On Viewport;
				Debugger.Expire(handle:FindFirstChild("SurfaceAppearance"), 0);
				handle.TextureID = skinLib.SurfaceAppearance["ColorMap"];
				
			end
			
		elseif handle then
			Debugger.Expire(handle:FindFirstChild("SurfaceAppearance"), 0);
			
			if skinLib.BaseColor then
				handle.Color = skinLib.BaseColor;
			end
			
			if skinLib.Textures then
				if handle:IsA("MeshPart") and jointName and skinLib.Textures[jointName] then
					handle.TextureID = skinLib.Textures[jointName];

				elseif handle:IsA("MeshPart") then
					handle.TextureID = skinLib.Textures["Handle"] or "";

				elseif not handle:IsA("MeshPart") then
					local mesh = handle:FindFirstChild("SpecialMesh");
					if mesh then
						mesh.TextureId = skinLib.Textures["Handle"];
					end
				end
			end
			
		end
		
		for _, obj in pairs(prefab:GetDescendants()) do
			if obj.Name == "Effects" then
				obj:Destroy();
			end
		end
		
		if skinLib.Effects then
			for partName, effectList in pairs(skinLib.Effects) do
				local parent = prefab:FindFirstChild(partName);
				if parent then
					for effectName, values in pairs(effectList) do
						local newEffect;
						
						if particlesFolder:FindFirstChild(values.Type) then
							newEffect = particlesFolder[values.Type]:Clone();
						else
							newEffect = Instance.new(values.Type);
						end
						
						newEffect.Name = "Effects";
						newEffect:SetAttribute("EffectName", effectName);
						
						if values.Properties then
							for k, v in pairs(values.Properties) do
								newEffect[k] = v;
							end
						end
						
						newEffect.Parent = parent;
						
						if values.AttachmentCFrame then
							local attach = Instance.new("Attachment");
							attach.Name = "Effects";
							attach:SetAttribute("EffectName", effectName);
							attach.CFrame = values.AttachmentCFrame;
							
							newEffect.Parent = attach;
							attach.Parent = parent;
						end
					end
				end
			end
		end
	end
end

function library.UpdateTexture(prefab, textureId)

	local handle = prefab:FindFirstChild("Handle");
	local jointName = prefab:GetAttribute("ClothingJoint");
	
	if handle then
		if handle:IsA("MeshPart") then
			if textureId then
				handle.TextureID = textureId;
			else
				return handle.TextureID
			end

		elseif not handle:IsA("MeshPart") then
			local mesh = handle:FindFirstChild("SpecialMesh");
			if mesh then
				if textureId then
					mesh.TextureId = textureId;
				else
					return mesh.TextureId
				end
			end
		end
	end
end

--== greytshirt
library:Add{
	Id="greytshirt";
	ItemId="greytshirt";
	Name="Default";
	Textures={
		["UT"]="rbxassetid://1744912817";
		["LT"]="rbxassetid://1744912817";
		["LUA"]="rbxassetid://1744912817";
		["RUA"]="rbxassetid://1744912817";
	}
};

library:Add{
	Id="greytshirtblue";
	ItemId="greytshirt";
	Name="Blue Color";
	Textures={
		["UT"]="rbxassetid://6535180507";
		["LT"]="rbxassetid://6535180507";
		["LUA"]="rbxassetid://6535180507";
		["RUA"]="rbxassetid://6535180507";
	}
};

library:Add{
	Id="greytshirticyblue";
	ItemId="greytshirt";
	Name="Icy Blue Pattern";
	Textures={
		["UT"]="rbxassetid://8532590435";
		["LT"]="rbxassetid://8532590435";
		["LUA"]="rbxassetid://8532590435";
		["RUA"]="rbxassetid://8532590435";
	};
	Unlocked=true;
};

library:Add{
	Id="greytshirticyred";
	ItemId="greytshirt";
	Name="Icy Red Pattern";
	Textures={
		["UT"]="rbxassetid://8532645802";
		["LT"]="rbxassetid://8532645802";
		["LUA"]="rbxassetid://8532645802";
		["RUA"]="rbxassetid://8532645802";
	};
	Unlocked=true;
};

library:Add{
	Id="greytshirtcamo";
	ItemId="greytshirt";
	Name="Camo Pattern";
	Textures={
		["UT"]="rbxassetid://6534965799";
		["LT"]="rbxassetid://6534965799";
		["LUA"]="rbxassetid://6534965799";
		["RUA"]="rbxassetid://6534965799";
	}
};

--== xmassweater
library:Add{
	Id="xmassweater";
	ItemId="xmassweater";
	Name="Default";
	Textures={
		["LLA"]="rbxassetid://6125956699";
		["LT"]="rbxassetid://6125956699";
		["LUA"]="rbxassetid://6125956699";
		["RUA"]="rbxassetid://6125956699";
		["RLA"]="rbxassetid://6125956699";
		["UT"]="rbxassetid://6125956699";
	}
};

library:Add{
	Id="xmassweatergreen";
	ItemId="xmassweater";
	Name="Green Red";
	Textures={
		["LLA"]="rbxassetid://6538903022";
		["LT"]="rbxassetid://6538903022";
		["LUA"]="rbxassetid://6538903022";
		["RUA"]="rbxassetid://6538903022";
		["RLA"]="rbxassetid://6538903022";
		["UT"]="rbxassetid://6538903022";
	}
};

library:Add{
	Id="xmassweateryellow";
	ItemId="xmassweater";
	Name="Yellow Blue";
	Textures={
		["LLA"]="rbxassetid://6538911498";
		["LT"]="rbxassetid://6538911498";
		["LUA"]="rbxassetid://6538911498";
		["RUA"]="rbxassetid://6538911498";
		["RLA"]="rbxassetid://6538911498";
		["UT"]="rbxassetid://6538911498";
	}
};

--== dufflebag
library:Add{
	Id="dufflebag";
	ItemId="dufflebag";
	Name="Default";
	Textures={
		["Handle"]="rbxassetid://8827951970";
	};
};

library:Add{
	Id="dufflebageaster1";
	ItemId="dufflebag";
	Name="Easter Colors";
	Textures={
		["Handle"]="rbxassetid://8828356403";
	}
};

library:Add{
	Id="dufflebageaster2";
	ItemId="dufflebag";
	Name="Easter Stripes";
	Textures={
		["Handle"]="rbxassetid://8828358153";
	}
};

library:Add{
	Id="dufflebagstreetart";
	ItemId="dufflebag";
	Name="Street Art";
	Textures={
		["Handle"]="rbxassetid://8828360678";
	}
};

library:Add{
	Id="dufflebagvintage";
	ItemId="dufflebag";
	Name="Vintage";
	Textures={
		["Handle"]="rbxassetid://8828363019";
	}
};

library:Add{
	Id="dufflebagarticscape";
	ItemId="dufflebag";
	Name="Artic Scape";
	Textures={
		["Handle"]="rbxassetid://8828364639";
	}
};

library:Add{
	Id="dufflebagfirstaidgreen";
	ItemId="dufflebag";
	Name="Green First Aid";
	Textures={
		["Handle"]="rbxassetid://8828399132";
	}
};

library:Add{
	Id="dufflebaggalaxy";
	ItemId="dufflebag";
	Icon="rbxassetid://12658727687";
	Name="Galaxy";
	Textures={
		["Handle"]="rbxassetid://12658706749";
	}
};

library:Add{
	Id="dufflebagorigins";
	ItemId="dufflebag";
	Name="Origins";
	SurfaceAppearance={
		ColorMap="rbxassetid://13975329840";
	};
};

--== prisonshirt
library:Add{
	Id="prisonshirt";
	ItemId="prisonshirt";
	Name="Default";
	Textures={
		["UT"]="rbxassetid://2013710081";
		["LT"]="rbxassetid://2013710081";
		["LUA"]="rbxassetid://2013710081";
		["RUA"]="rbxassetid://2013710081";
	};
};

library:Add{
	Id="prisonshirtblue";
	ItemId="prisonshirt";
	Name="Blue";
	Textures={
		["UT"]="rbxassetid://6665638674";
		["LT"]="rbxassetid://6665638674";
		["LUA"]="rbxassetid://6665638674";
		["RUA"]="rbxassetid://6665638674";
	};
};

--== prisonpants
library:Add{
	Id="prisonpants";
	ItemId="prisonpants";
	Name="Default";
	Textures={
		["LLL"]="rbxassetid://5627732537";
		["LUL"]="rbxassetid://5627732537";
		["RLL"]="rbxassetid://5627732537";
		["RUL"]="rbxassetid://5627732537";
	};
};

library:Add{
	Id="prisonpantsblue";
	ItemId="prisonpants";
	Name="Blue";
	Textures={
		["LLL"]="rbxassetid://6665658904";
		["LUL"]="rbxassetid://6665658904";
		["RLL"]="rbxassetid://6665658904";
		["RUL"]="rbxassetid://6665658904";
	};
};

--== bunnymanhead
library:Add{
	Id="bunnymanhead";
	ItemId="bunnymanhead";
	Name="Default";
	Textures={
		["Handle"]="rbxassetid://50380653";
	};
};

library:Add{
	Id="bunnymanheadbenefactor";
	ItemId="bunnymanhead";
	Name="The Benefactor";
	Textures={
		["Handle"]="rbxassetid://6665865055";
	};
};

--== plankarmor
library:Add{
	Id="plankarmor";
	ItemId="plankarmor";
	Name="Default";
	Textures={
		["Handle"]="rbxassetid://6952680257";
	};
};

library:Add{
	Id="plankarmormaple";
	ItemId="plankarmor";
	Name="Maple";
	Textures={
		["Handle"]="rbxassetid://6956425630";
	};
};

library:Add{
	Id="plankarmorash";
	ItemId="plankarmor";
	Name="Ash";
	Textures={
		["Handle"]="rbxassetid://6956426986";
	};
};


--== gasmask
library:Add{
	Id="gasmask";
	ItemId="gasmask";
	Name="Default";
	Textures={
		["Handle"]="rbxassetid://6971951196";
	};
};

library:Add{
	Id="gasmaskwhite";
	ItemId="gasmask";
	Name="White";
	Textures={
		["Handle"]="rbxassetid://7021561911";
	};
};

library:Add{
	Id="gasmaskblue";
	ItemId="gasmask";
	Name="Blue";
	Textures={
		["Handle"]="rbxassetid://7021611834";
	};
};

library:Add{
	Id="gasmaskyellow";
	ItemId="gasmask";
	Name="Yellow";
	Textures={
		["Handle"]="rbxassetid://7021613643";
	};
};

library:Add{
	Id="gasmaskunionjack";
	ItemId="gasmask";
	Name="The Union Jack";
	Textures={
		["Handle"]="rbxassetid://7021629071";
	};
};

library:Add{
	Id="gasmaskxmas";
	ItemId="gasmask";
	Name="Christmas";
	Textures={
		["Handle"]="rbxassetid://8402317276";
	};
};


--== scraparmor
library:Add{
	Id="scraparmor";
	ItemId="scraparmor";
	Name="Default";
	Textures={
		["Handle"]="rbxassetid://8366768416";
	};
};

library:Add{
	Id="scraparmorcopper";
	ItemId="scraparmor";
	Name="Copper";
	Textures={
		["Handle"]="rbxassetid://7021770174";
	};
};

library:Add{
	Id="scraparmorbiox";
	ItemId="scraparmor";
	Name="BioX";
	Textures={
		["Handle"]="rbxassetid://8366899696";
	};
};

library:Add{
	Id="scraparmorcherryblossom";
	ItemId="scraparmor";
	Name="Cherry Blossom";
	Textures={
		["Handle"]="rbxassetid://12964120126";
	};
};

library:Add{
	Id="scraparmormissingtextures";
	ItemId="scraparmor";
	Name="Missing Textures";
	Textures={
		["Handle"]="rbxassetid://15241466985";
	};
};


--== watch
library:Add{
	Id="watch";
	ItemId="watch";
	Name="Default";
	Textures={
		["Handle"]="rbxassetid://6306893198";
	};
};

library:Add{
	Id="watchyellow";
	ItemId="watch";
	Name="Yellow";
	Textures={
		["Handle"]="rbxassetid://13021453507";
	};
};

--== brownbelt
library:Add{
	Id="brownbelt";
	ItemId="brownbelt";
	Name="Default";
	Textures={
		["Handle"]="rbxassetid://1744577580";
	};
};

library:Add{
	Id="brownbeltwhite";
	ItemId="brownbelt";
	Name="White";
	Textures={
		["Handle"]="rbxassetid://13021977407";
	};
};

--== inflatablebuoy
library:Add{
	Id="inflatablebuoy";
	ItemId="inflatablebuoy";
	Name="Default";
	SurfaceAppearance={
		ColorMap="rbxassetid://10392911200";
	};
};

library:Add{
	Id="inflatablebuoyrat";
	ItemId="inflatablebuoy";
	Name="R.A.T.";
	SurfaceAppearance={
		ColorMap="rbxassetid://13021400982";
	};
};


--== tophat
library:Add{
	Id="tophat";
	ItemId="tophat";
	Name="Default";
	Textures={
		["Handle"]="rbxassetid://7558531740";
	};
};

library:Add{
	Id="tophatgrey";
	ItemId="tophat";
	Name="Grey";
	Textures={
		["Handle"]="rbxassetid://7647933560";
	};
};

library:Add{
	Id="tophatpurple";
	ItemId="tophat";
	Name="Purple";
	Textures={
		["Handle"]="rbxassetid://7647969340";
	};
};

library:Add{
	Id="tophatred";
	ItemId="tophat";
	Name="Red";
	Textures={
		["Handle"]="rbxassetid://7647970841";
	};
};

library:Add{
	Id="tophatgold";
	ItemId="tophat";
	Name="Gold";
	Textures={
		["Handle"]="rbxassetid://7647971874";
	};
};

--== clownmask
library:Add{
	Id="clownmask";
	ItemId="clownmask";
	Name="Default";
	Textures={
		["Handle"]="rbxassetid://7558506950";
	};
};

library:Add{
	Id="clownmaskus";
	ItemId="clownmask";
	Name="Star Spangled Banner";
	Textures={
		["Handle"]="rbxassetid://8367138629";
	};
};

library:Add{
	Id="clownmaskmissjoyful";
	ItemId="clownmask";
	Name="Miss Joyful";
	Textures={
		["Handle"]="rbxassetid://11269669005";
	};
};

--== disguisekit
library:Add{
	Id="disguisekit";
	ItemId="disguisekit";
	Name="Default";
	Textures={
		["Handle"]="rbxassetid://8377407358";
	};
};

library:Add{
	Id="disguisekitxmas";
	ItemId="disguisekit";
	Name="Christmas";
	Textures={
		["Handle"]="rbxassetid://8377612797";
	};
};

library:Add{
	Id="disguisekitwhite";
	ItemId="disguisekit";
	Name="White";
	Textures={
		["Handle"]="rbxassetid://8377619853";
	};
};

--== zriceraskull
library:Add{
	Id="zriceraskull";
	ItemId="zriceraskull";
	Name="Default";
	Textures={
		["Handle"]="rbxassetid://8377606395";
	};
};

library:Add{
	Id="zriceraskullinferno";
	ItemId="zriceraskull";
	Name="Inferno";
	Textures={
		["Handle"]="rbxassetid://8378276517";
	};
	Effects={
		["Handle"]={
			fire1={Type="Fire3"; Properties={ZOffset=0;}; AttachmentCFrame=CFrame.new(0.00879669189, -0.46296978, 0.129806519, 1, 1.75416548e-09, 4.95361885e-09, 1.75417059e-09, 0.777145982, -0.629320443, -4.95361663e-09, 0.629320443, 0.777145982)}
		}
	}
};

--== vexgloves
library:Add{
	Id="vexgloves";
	ItemId="vexgloves";
	Name="Default";
	Textures={
		["LH"]="rbxassetid://7181335578";
		["RH"]="rbxassetid://7181335578";
	};
};

library:Add{
	Id="vexglovesinferno";
	ItemId="vexgloves";
	Name="Inferno";
	Textures={
		["LH"]="rbxassetid://13974317312";
		["RH"]="rbxassetid://13974317312";
	};
	Effects={
		["Handle"]={
			fire1={Type="Fire3"; Properties={ZOffset=0; LockedToPart=true; Rate=6;}; AttachmentCFrame=CFrame.new(0,0,0)}
		}
	}
};


--== survivorsbackpack
library:Add{
	Id="survivorsbackpack";
	ItemId="survivorsbackpack";
	Name="Default";
	Textures={
		["Handle"]="rbxassetid://8948195578";
	};
};

library:Add{
	Id="survivorsbackpackgalaxy";
	Icon="rbxassetid://8948315976"; -- unlockable item does not exist;
	ItemId="survivorsbackpack";
	Name="Galaxy";
	Textures={
		["Handle"]="rbxassetid://8948365095";
	};
};


--== divinggoggles
library:Add{
	Id="divinggoggles";
	ItemId="divinggoggles";
	Name="Default";
	SurfaceAppearance={
		ColorMap="rbxassetid://10332602803";
	};
};

library:Add{
	Id="divinggogglesyellow";
	ItemId="divinggoggles";
	Name="Yellow";
	SurfaceAppearance={
		ColorMap="rbxassetid://10333042522";
	};
};

library:Add{
	Id="divinggogglesred";
	ItemId="divinggoggles";
	Name="Red";
	SurfaceAppearance={
		ColorMap="rbxassetid://15008750665";
	};
};


--== divinggoggles
library:Add{
	Id="maraudersmask";
	ItemId="maraudersmask";
	Name="Default";
	SurfaceAppearance={
		ColorMap="rbxassetid://11269231309";
	};
};

library:Add{
	Id="maraudersmaskblue";
	ItemId="maraudersmask";
	Name="Blue";
	SurfaceAppearance={
		ColorMap="rbxassetid://11269776200";
	};
};

library:Add{
	Id="maraudersmaskcbspumpkins";
	ItemId="maraudersmask";
	Name="Cute But Scary Pumpkins";
	SurfaceAppearance={
		ColorMap="rbxassetid://15016807876";
	};
};


--== santahat
library:Add{
	Id="santahat";
	ItemId="santahat";
	Name="Default";
	Textures={
		["Handle"]="rbxassetid://11812457660";
	};
};

library:Add{
	Id="santahatwinterfest";
	ItemId="santahat";
	Name="Frostivus";
	Textures={
		["Handle"]="rbxassetid://11812462035";
	};
};

--== mercskneepads
library:Add{
	Id="mercskneepads";
	ItemId="mercskneepads";
	Name="Default";
	SurfaceAppearance={
		ColorMap="rbxassetid://11026319430";
	};
};

library:Add{
	Id="mercskneepadswinterfest";
	ItemId="mercskneepads";
	Name="Frostivus";
	SurfaceAppearance={
		ColorMap="rbxassetid://11812673616";
	};
};


--== highvisjacket
library:Add{
	Id="highvisjacket";
	ItemId="highvisjacket";
	Name="Default";
	Textures={
		["LLA"]="rbxassetid://12653367270";
		["LT"]="rbxassetid://12653367270";
		["LH"]="rbxassetid://12653367270";
		["LUA"]="rbxassetid://12653367270";
		["RLA"]="rbxassetid://12653367270";
		["RUA"]="rbxassetid://12653367270";
		["UT"]="rbxassetid://12653367270";
	};
};

library:Add{
	Id="highvisjacketgalaxy";
	ItemId="highvisjacket";
	Icon="rbxassetid://12658731830";
	Name="Galaxy";
	Textures={
		["LLA"]="rbxassetid://12653382051";
		["LT"]="rbxassetid://12653382051";
		["LH"]="rbxassetid://12653382051";
		["LUA"]="rbxassetid://12653382051";
		["RLA"]="rbxassetid://12653382051";
		["RUA"]="rbxassetid://12653382051";
		["UT"]="rbxassetid://12653382051";
	};
};

library:Add{
	Id="highvisjacketfallenleaves";
	ItemId="highvisjacket";
	Icon="rbxassetid://12963945448";
	Name="Fallen Leaves";
	Textures={
		["LLA"]="rbxassetid://12964022505";
		["LT"]="rbxassetid://12964022505";
		["LH"]="rbxassetid://12964022505";
		["LUA"]="rbxassetid://12964022505";
		["RLA"]="rbxassetid://12964022505";
		["RUA"]="rbxassetid://12964022505";
		["UT"]="rbxassetid://12964022505";
	};
};


--== cultisthood

library:Add{
	Id="cultisthood";
	ItemId="cultisthood";
	Name="Default";
	BaseColor=Color3.fromRGB(34, 36, 44);
};

library:Add{
	Id="cultisthoodnekros";
	ItemId="cultisthood";
	Name="Nekros";
	BaseColor=Color3.fromRGB(89, 0, 1);
};

--== skullmask

library:Add{
	Id="skullmask";
	ItemId="skullmask";
	Name="Default";
	SurfaceAppearance={
		ColorMap="rbxassetid://11235294308";
	};
};

library:Add{
	Id="skullmaskgold";
	ItemId="skullmask";
	Name="Gold";
	SurfaceAppearance={
		ColorMap="rbxassetid://15007537005";
	};
};



local modModEngineService = require(game.ReplicatedStorage.Library:WaitForChild("ModEngineService"));
local moddedSelf = modModEngineService:GetModule(script.Name);
if moddedSelf then moddedSelf:Init(library); end

return library;