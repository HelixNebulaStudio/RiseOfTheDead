return {
	leave={GetText=function(factionData, values)
		local members = factionData.Members
		local rStr = "";

		local s, e = pcall(function() 
			local memberData1 = members[values[1]];
			local name1 = memberData1 and memberData1.Name or values[1];

			rStr = name1 .." left the faction.";
		end) if not s then rStr = e end;

		return rStr;
	end};

	kick={GetText=function(factionData, values)
		local members = factionData.Members
		local rStr = "";

		local s, e = pcall(function() 
			local memberData1 = members[values[1]];
			local name1 = memberData1 and memberData1.Name or values[1];
			local memberData2 = members[values[2]];
			local name2 = memberData2 and memberData2.Name or values[2];

			rStr = name1.." kicked ".. name2 ..".";
		end) if not s then rStr = e end;

		return rStr;
	end};

	setrole={GetText=function(factionData, values)
		local members = factionData.Members
		local rStr = "";

		local s, e = pcall(function() 
			local memberData1 = members[values[1]];
			local name1 = memberData1 and memberData1.Name or values[1];
			local memberData2 = members[values[2]];
			local name2 = memberData2 and memberData2.Name or values[2];

			rStr = name1.." set "..name2.."'s role to "..values[3];
		end) if not s then rStr = e end;

		return rStr;
	end};

	newrole={GetText=function(factionData, values)
		local members = factionData.Members
		local rStr = "";

		local s, e = pcall(function() 
			local memberData1 = members[values[1]];
			local name1 = memberData1 and memberData1.Name or values[1];

			rStr = name1.." created role "..values[2];
		end) if not s then rStr = e end;

		return rStr;
	end};

	configrole={GetText=function(factionData, values)
		local members = factionData.Members
		local rStr = "";

		local s, e = pcall(function() 
			local memberData1 = members[values[1]];
			local name1 = memberData1 and memberData1.Name or values[1];

			rStr = name1.." updated role "..values[2];
		end) if not s then rStr = e end;

		return rStr;
	end};

	delrole={GetText=function(factionData, values)
		local members = factionData.Members
		local rStr = "";

		local s, e = pcall(function() 
			local memberData1 = members[values[1]];
			local name1 = memberData1 and memberData1.Name or values[1];

			rStr = name1.." deleted role "..values[2];
		end) if not s then rStr = e end;

		return rStr;
	end};

	editinfo={GetText=function(factionData, values)
		local members = factionData.Members
		local rStr = "";

		local s, e = pcall(function() 
			local memberData1 = members[values[1]];
			local name1 = memberData1 and memberData1.Name or values[1];

			rStr = name1.." edited faction info.";
		end) if not s then rStr = e end;

		return rStr;
	end};

	acceptinvite={GetText=function(factionData, values)
		local members = factionData.Members
		local rStr = "";

		local s, e = pcall(function() 
			local memberData1 = members[values[1]];
			local name1 = memberData1 and memberData1.Name or values[1];

			rStr = name1.." accepted invite request of "..values[2];
		end) if not s then rStr = e end;

		return rStr;
	end};

	denyinvite={GetText=function(factionData, values)
		local members = factionData.Members
		local rStr = "";

		local s, e = pcall(function() 
			local memberData1 = members[values[1]];
			local name1 = memberData1 and memberData1.Name or values[1];

			rStr = name1.." declined invite request of "..values[2];
		end) if not s then rStr = e end;

		return rStr;
	end};
	
	resourcechange={GetText=function(factionData, values)
		local members = factionData.Members
		local rStr = "";

		local s, e = pcall(function() 
			rStr = "Resources Change: "..(values.Value >= 0 and "+" or "").. values.Value .."% "..values.Key;
		end) if not s then rStr = e end;

		return rStr;
	end};
	
	startmission={GetText=function(factionData, values)
		local members = factionData.Members
		local rStr = "";
		
		local s, e = pcall(function() 
			local memberData1 = members[values[1]];
			local name1 = memberData1 and memberData1.Name or values[1];

			rStr = tostring(name1).." started mission: ".. tostring(values[2]);
			
		end) if not s then rStr = e end;

		return rStr;
	end};

	completemission={GetText=function(factionData, values)
		local members = factionData.Members
		local rStr = "";

		local s, e = pcall(function() 
			local memberData1 = members[values[1]];
			local name1 = memberData1 and memberData1.Name or values[1];

			rStr = tostring(name1).." completed mission: ".. tostring(values[2]);

		end) if not s then rStr = e end;

		return rStr;
	end};

	sethqhost={GetText=function(factionData, values)
		local members = factionData.Members
		local rStr = "";

		local s, e = pcall(function() 
			local memberData1 = members[values[1]];
			local name1 = memberData1 and memberData1.Name or values[1];

			rStr = name1.." set headquarter host to ".. tostring(values[2]) ..".";
		end) if not s then rStr = e end;

		return rStr;
	end};
	
	addgold={GetText=function(factionData, values)
		local amt = values[1];
		local reason = values[2];
		
		local rStr = "";
		
		rStr = (math.sign(amt) == 1 and "+" or "").. amt .." Gold : "..reason;

		return rStr;
	end};
	
	sentjoinrequest={GetText=function(factionData, values)
		local name = values[1];

		local rStr = "";

		rStr = name .." sent a join request.";

		return rStr;
	end};
}