local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local RotdCore = {};
--==
local modOnEventsHandlers = require(game.ReplicatedStorage.Library.OnEventHandlersRotd :: ModuleScript);
local modEquipmentClassRotd = require(game.ReplicatedStorage.Library.EquipmentClassRotd :: ModuleScript);
local modClothingLibraryRotd = require(game.ReplicatedStorage.Library.ClothingLibraryRotd :: ModuleScript);

modEquipmentClassRotd:Init();
Debugger:Warn("Init RotdCore.");
return RotdCore;