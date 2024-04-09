local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local Instrument = {};
Instrument.__index = Instrument;

local UserInputService = game:GetService("UserInputService");
local RunService = game:GetService("RunService");
local CollectionService = game:GetService("CollectionService");
local TweenService = game:GetService("TweenService");

local modRemotesManager = require(game.ReplicatedStorage.Library.RemotesManager);
local remoteInstrumentRemote = modRemotesManager:Get("InstrumentRemote");
--==
Instrument.NoteIndex = {["C"]=0; ["C#"]=1; ["D"]=2; ["D#"]=3; ["E"]=4; ["F"]=5; ["F#"]=6; ["G"]=7; ["G#"]=8; ["A"]=9; ["A#"]=10; ["B"]=11;};

Instrument.Notes = {
	{Name="C"; Key="A"; KeyCode=Enum.KeyCode.A; Index=1;
		AdvKey={ {Key="A"; KeyCode=Enum.KeyCode.A;}; {Key="Q"; KeyCode=Enum.KeyCode.Q;}; {Key="1"; KeyCode=Enum.KeyCode.One;}; };
	};
	{Name="C#"; Key="W"; KeyCode=Enum.KeyCode.W; Sharp=true; Index=2;
		AdvKey={ {Key="S"; KeyCode=Enum.KeyCode.S;}; {Key="W"; KeyCode=Enum.KeyCode.W;}; {Key="2"; KeyCode=Enum.KeyCode.Two;}; };
	};
	{Name="D"; Key="S"; KeyCode=Enum.KeyCode.S; Index=3;
		AdvKey={ {Key="D"; KeyCode=Enum.KeyCode.D;}; {Key="E"; KeyCode=Enum.KeyCode.E;}; {Key="3"; KeyCode=Enum.KeyCode.Three;}; };
	};
	{Name="D#"; Key="E"; KeyCode=Enum.KeyCode.E; Sharp=true; Index=4;
		AdvKey={ {Key="F"; KeyCode=Enum.KeyCode.F;}; {Key="R"; KeyCode=Enum.KeyCode.R;}; {Key="4"; KeyCode=Enum.KeyCode.Four;}; };
	};
	{Name="E"; Key="D"; KeyCode=Enum.KeyCode.D; Index=5;
		AdvKey={ {Key="G"; KeyCode=Enum.KeyCode.G;}; {Key="T"; KeyCode=Enum.KeyCode.T;}; {Key="5"; KeyCode=Enum.KeyCode.Five;}; };
	};
	{Name="F"; Key="F"; KeyCode=Enum.KeyCode.F; Index=6;
		AdvKey={ {Key="H"; KeyCode=Enum.KeyCode.H;}; {Key="Y"; KeyCode=Enum.KeyCode.Y;}; {Key="6"; KeyCode=Enum.KeyCode.Six;}; };
	};
	{Name="F#"; Key="T"; KeyCode=Enum.KeyCode.T; Sharp=true; Index=7;
		AdvKey={ {Key="J"; KeyCode=Enum.KeyCode.J;}; {Key="U"; KeyCode=Enum.KeyCode.U;}; {Key="7"; KeyCode=Enum.KeyCode.Seven;}; };
	};
	{Name="G"; Key="G"; KeyCode=Enum.KeyCode.G; Index=8;
		AdvKey={ {Key="K"; KeyCode=Enum.KeyCode.K;}; {Key="I"; KeyCode=Enum.KeyCode.I;}; {Key="8"; KeyCode=Enum.KeyCode.Eight;}; };
	};
	{Name="G#"; Key="Y"; KeyCode=Enum.KeyCode.Y; Sharp=true; Index=9;
		AdvKey={ {Key="L"; KeyCode=Enum.KeyCode.L;}; {Key="O"; KeyCode=Enum.KeyCode.O;}; {Key="9"; KeyCode=Enum.KeyCode.Nine;}; };
	};
	{Name="A"; Key="H"; KeyCode=Enum.KeyCode.H; Index=10;
		AdvKey={ {Key=";"; KeyCode=Enum.KeyCode.Semicolon;}; {Key="P"; KeyCode=Enum.KeyCode.P;}; {Key="0"; KeyCode=Enum.KeyCode.Zero;}; };
	};
	{Name="A#"; Key="U"; KeyCode=Enum.KeyCode.U; Sharp=true; Index=11;
		AdvKey={ {Key="'"; KeyCode=Enum.KeyCode.Quote;}; {Key="["; KeyCode=Enum.KeyCode.LeftBracket;}; {Key="-"; KeyCode=Enum.KeyCode.Minus;}; };
	};
	{Name="B"; Key="J"; KeyCode=Enum.KeyCode.J; Index=12;
		AdvKey={ {Key="\\"; KeyCode=Enum.KeyCode.BackSlash;}; {Key="]"; KeyCode=Enum.KeyCode.RightBracket;}; {Key="="; KeyCode=Enum.KeyCode.Equals;}; };
	};
};

Instrument.InstrumentSounds={
	Flute=script:WaitForChild("Flute");
	Guitar=script:WaitForChild("Guitar");
	Keytar=script:WaitForChild("Keytar");
};

Instrument.InstrumentLibrary={
	Flute={
		Volume=2;
		FadeOutDuration=0.2;
		FadeOutStart=1.5;
	};
	Guitar={
		Volume=2;
		FadeOutDuration=0.5;
		FadeOutStart=1;
	};
	Keytar={
		Volume=2;
		FadeOutDuration=1.5;
		FadeOutStart=2.5;
	}
}
--==

function Instrument.new(instrument, handle, notePart)
	local self = {
		Instrument=instrument;
		Player=nil;
		StorageItem=nil;
		
		IsShiftDown = false;
		IsCtrlDown = false;
		
		AdvanceMode = false;
		
		Handle=handle;
		NotePart=notePart;
		
		Notes={};
		LastNotes={};
		
		NoteSounds={};
		
		LastOctave = 12;
		
		NoteStepTime = Instrument.InstrumentSounds[instrument].TimeLength/36;
	};
	
	local instrumentLib = Instrument.InstrumentLibrary[self.Instrument];
	if instrumentLib then
		if instrumentLib.NoteSounds == nil then
			instrumentLib.NoteSounds = {};
			
			for _, snd in pairs(script:WaitForChild(self.Instrument.."Notes"):GetChildren()) do
				instrumentLib.NoteSounds[snd.Name] = snd;
			end
		end
	end
	
	if RunService:IsClient() then
		
		local lastShift, lastCtrl = false, false;
		
		self.LastPlayed = nil;
		self.Loop = RunService.Heartbeat:Connect(function(delta)
			if not self.Handle:IsDescendantOf(workspace) then self:Destroy() end;
			
			local isPlayingInstrument = false;
			
			for noteId, active in pairs(self.Notes) do
				local noteSound = self.NoteSounds[noteId];
				
				if noteSound then
					local fadeOutStart = instrumentLib.FadeOutStart;

					local function fadeOut(duration)
						if noteSound.Volume < instrumentLib.Volume then return end;

						TweenService:Create(noteSound, TweenInfo.new(duration), {
							Volume=0;
						}):Play();

						Debugger.Expire(noteSound, duration);
					end

					if active == true then
						isPlayingInstrument = true;
						self.LastPlayed = tick();

						if noteSound.TimePosition <= fadeOutStart then
							noteSound.Volume = instrumentLib.Volume;

						else
							if noteSound.Volume == instrumentLib.Volume then
								fadeOut(noteSound.TimeLength-noteSound.TimePosition-0.1);
							end

						end

					else
						self.NoteSounds[noteId] = nil;
						fadeOut(instrumentLib.FadeOutDuration);

					end
					
				elseif active == true then
					local noteName, octave = unpack(string.split(noteId, ":"));
					self:SpawnNote(noteName, tonumber(octave) or 5);
					
				end
				
				
			end
			
			
			if not isPlayingInstrument and self.LastPlayed and (tick()-self.LastPlayed > 2) then
				self.LastPlayed = tick();
				self:Replicate();
			end
		end)
	end
	
	setmetatable(self, Instrument);
	return self;
end

function Instrument:Replicate()
	if self.Player ~= game.Players.LocalPlayer then return end
		
	local changedNotes = {};
	for noteId, active in pairs(self.Notes) do
		if self.LastNotes[noteId] ~= active then
			self.LastNotes[noteId] = active;
			changedNotes[noteId] = active;
		end
	end
	
	local packet = {
		StorageItemID = self.StorageItem.ID;
		Prefabs = {self.Handle.Parent};
		Data = changedNotes;
	}
	
	remoteInstrumentRemote:Fire(modRemotesManager.Compress(packet));
end

function Instrument:Sync(notesChanged)
	self.LastSync = tick();
	
	local emittedParticle = false;
	
	for noteId, active in pairs(notesChanged) do
		if not notesChanged and self.Handle:IsDescendantOf(workspace) and self.Handle:FindFirstChild("musicParticle") then
			self.Handle.musicParticle:Emit(1);
			emittedParticle = true;
		end
		
		self.Notes[noteId] = active;
	end
	
	task.delay(5, function()
		if tick()-self.LastSync < 5 then return end;
		
		for noteId, active in pairs(self.Notes) do
			self.Notes[noteId] = false;
		end
	end)
	
	--local notesChanged = false;
	--for _, note in pairs(Instrument.Notes) do
	--	if notes[note.Name] ~= nil then
	--		if not notesChanged and self.Handle:IsDescendantOf(workspace) and self.Handle:FindFirstChild("musicParticle") then
	--			self.Handle.musicParticle:Emit(1);
	--		end
	--		notesChanged = true;
	--		self.Notes[note.Name] = notes[note.Name];
	--	else
	--		self.Notes[note.Name] = false;
	--	end
	--end
	
	--task.delay(5, function()
	--	if tick()-self.LastSync < 5 then return end;

	--	for _, note in pairs(Instrument.Notes) do
	--		self.Notes[note.Name] = false;
	--	end
	--end)
end

--function Instrument:GetNoteSound(instructmentSound, noteName)
--	local noteSound = self.NoteSounds[noteName];
	
--	if noteSound == nil then
--		self.NoteSounds[noteName] = instructmentSound:Clone();
--		noteSound = self.NoteSounds[noteName];
--		noteSound.Name = noteName;
		
--		if self.Player == game.Players.LocalPlayer then
--			noteSound.Parent = workspace;
--		else
--			noteSound.Parent = self.Handle;
--		end
		
--		noteSound.SoundGroup = game.SoundService:FindFirstChild("InstrumentMusic");
--		noteSound:SetAttribute("Volume", noteSound.Volume);
		
--		noteSound:SetAttribute("SoundOwner", self.Player and self.Player.Name or nil);
--		CollectionService:AddTag(noteSound, "PlayerNoiseSounds");

--		local octave = self.IsShiftDown and 24 or self.IsCtrlDown and 0 or 12;
--		local noteStartTime = self.NoteStepTime * (Instrument.NoteIndex[noteName] + octave);

--		noteSound.TimePosition = noteStartTime;
--	end
	
--	return noteSound;
--end

function Instrument:GetInputNote(inputObject)
	for a=1, #Instrument.Notes do
		local note = Instrument.Notes[a];
		local noteName = note.Name;

		if self.AdvanceMode then
			local found = false;
			for b=-1, 1 do
				local index = b+2;
				local advKeyInfo = note.AdvKey[index];

				if advKeyInfo.KeyCode == inputObject.KeyCode then
					found = true;

					return {
						Name=noteName;
						Octave=5+b;
						Key = advKeyInfo.Key;
						KeyCode = advKeyInfo.KeyCode;
					}
				end
			end
			if found then break; end;

		else
			if inputObject.KeyCode == note.KeyCode then
				return {
					Name=noteName;
					Octave=self.IsShiftDown and 6 or self.IsCtrlDown and 4 or 5;
					Key = note.Key;
					KeyCode = note.KeyCode;
				};
			end

		end
	end
end

function Instrument:SpawnNote(noteName, octave)
	local noteId = noteName..":"..octave;
	
	local instrumentLib = Instrument.InstrumentLibrary[self.Instrument];
	if instrumentLib then
		local noteSound = instrumentLib.NoteSounds[noteName]:Clone();
		self.NoteSounds[noteId] = noteSound;

		if self.Player == game.Players.LocalPlayer then
			noteSound.Parent = workspace;
		else
			noteSound.Parent = self.Handle;
		end

		noteSound.SoundGroup = game.SoundService:FindFirstChild("InstrumentMusic");

		noteSound:SetAttribute("SoundOwner", self.Player and self.Player.Name or nil);
		CollectionService:AddTag(noteSound, "PlayerNoiseSounds");

		if octave ~= 5 then
			local newPitchShift = Instance.new("PitchShiftSoundEffect");
			newPitchShift.Octave = octave == 4 and 0.5 or octave == 6 and 2 or 1.25;
			newPitchShift.Parent = noteSound;

		end

		noteSound:Play();
	end
end

function Instrument:ProcessInputBegan(inputObject)
	if not self.Handle:IsDescendantOf(workspace) then return end;
	
	--if inputObject.KeyCode == note.KeyCode then
	--	if not notesChanged and self.Handle:IsDescendantOf(workspace) and self.Handle:FindFirstChild("musicParticle") then
	--		self.Handle.musicParticle:Emit(1);
	--	end
		
	--	notesChanged = true;
	--	self.Notes[noteName] = true;

	--	local instrumentLib = Instrument.InstrumentLibrary[self.Instrument];
	--	if instrumentLib then
	--		self.NoteSounds[noteName] = instrumentLib.NoteSounds[noteName]:Clone();
	--		local noteSound = self.NoteSounds[noteName];
			
	--		if self.Player == game.Players.LocalPlayer then
	--			noteSound.Parent = workspace;
	--		else
	--			noteSound.Parent = self.Handle;
	--		end
			
	--		noteSound.SoundGroup = game.SoundService:FindFirstChild("InstrumentMusic");

	--		noteSound:SetAttribute("SoundOwner", self.Player and self.Player.Name or nil);
	--		CollectionService:AddTag(noteSound, "PlayerNoiseSounds");

	--		local octave = self.IsShiftDown and 24 or self.IsCtrlDown and 0 or 12;
	--		if octave ~= 12 then
	--			local newPitchShift = Instance.new("PitchShiftSoundEffect");
	--			newPitchShift.Octave = octave/12;
	--			newPitchShift.Parent = noteSound;
	--		end
			
	--		noteSound:Play();
			
	--	else
	--		local instructmentSound = Instrument.InstrumentSounds[self.Instrument];
	--		local noteSound = self:GetNoteSound(instructmentSound, noteName);

	--		local octave = self.IsShiftDown and 24 or self.IsCtrlDown and 0 or 12;
	--		local noteStartTime = self.NoteStepTime * (Instrument.NoteIndex[noteName] + octave);

	--		noteSound.Volume = 1;
	--		noteSound.TimePosition = noteStartTime;
	--		if not noteSound.Playing then
	--			noteSound:Resume();
	--		end
	--	end
	--end
	
	local activeNoteInfo = self:GetInputNote(inputObject);

	if activeNoteInfo == nil then return end; 
	if self.Handle:IsDescendantOf(workspace) and self.Handle:FindFirstChild("musicParticle") then
		self.Handle.musicParticle:Emit(1);
	end

	local noteName = activeNoteInfo.Name;
	local octave = activeNoteInfo.Octave;
	
	local noteId = noteName..":"..octave;
	
	self.Notes[noteId] = true;
	self:SpawnNote(noteName, octave);
	
	self:Replicate();
end

function Instrument:ProcessInputEnded(inputObject)
	if not self.Handle:IsDescendantOf(workspace) then return end;
	
	--local notesChanged = false;
	--for a=1, #Instrument.Notes do
	--	local note = Instrument.Notes[a];
	--	local noteName = note.Name;

	--	if inputObject.KeyCode == note.KeyCode then
	--		notesChanged = true;
	--		self.Notes[noteName] = false;

	--	end
	--end
	
	--if notesChanged then self:Replicate(); end;
	
	local activeNoteInfo = self:GetInputNote(inputObject);
	if activeNoteInfo == nil then return end;

	local noteName = activeNoteInfo.Name;
	local octave = activeNoteInfo.Octave;
	local noteId = noteName..":"..octave;
	
	if self.AdvanceMode then
		self.Notes[noteId] = false;
		
	else
		self.Notes[noteName..":4"] = false;
		self.Notes[noteName..":5"] = false;
		self.Notes[noteName..":6"] = false;
		
	end
	
	self:Replicate();
end

function Instrument:Destroy()
	self.IsShiftDown = false;
	self.IsCtrlDown = false;
	self.Notes={};
	self:Replicate()
	
	self.Loop:Disconnect();
	for _, snd in pairs(self.NoteSounds) do snd:Destroy(); end
end

return Instrument;