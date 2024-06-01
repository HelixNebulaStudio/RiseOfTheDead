local NotificationsLibrary = {
	["Inform"]=function(message, player)
		return {
			Message=message;
			ExtraData={
				ChatColor=Color3.fromRGB(85, 255, 255);
				Font = Enum.Font.Arial;
			};
		}
	end;
	
	["Reward"]=function(message, player)
		return {
			Message=message;
			ExtraData={
				ChatColor=Color3.fromRGB(149, 221, 115);
			};
		}
	end;
	
	["Negative"]=function(message, player)
		return {
			Imp=true;
			Message=message;
			ExtraData={
				ChatColor=Color3.fromRGB(255, 69, 69);
			};
		}
	end;
	
	["Positive"]=function(message, player)
		return {
			Message=message;
			ExtraData={
				ChatColor=Color3.fromRGB(149, 221, 115);
				Font = Enum.Font.ArialBold;
			};
		}
	end;
	
	["PickUp"]=function(message, player)
		return {
			Presist=false;
			Message=message.." has been added to inventory.";
			ExtraData={
				ChatColor=Color3.fromRGB(255, 183, 0);
			};
		}
	end;
	
	["PickUpCustom"]=function(message, player)
		return {
			Presist=false;
			Message=message;
			ExtraData={
				ChatColor=Color3.fromRGB(255, 183, 0);
			};
		}
	end;
	
	["Message"]=function(message, player)
		return {
			Message=message;
			ExtraData={
				ChatColor=Color3.fromRGB(255, 255, 255);
				Font = Enum.Font.Arial;
			};
		}
	end;
	
	["OnPremium"]=function(message, player)
		return {
			Message=message;
			ExtraData={
				ChatColor=Color3.fromRGB(170, 120, 0);
				Font = Enum.Font.ArialBold;
			};
		}
	end;
	
	["BossDefeat"]=function(message, player)
		return {
			Message=message.." has been defeated!";
			ExtraData={
				ChatColor=Color3.fromRGB(255, 102, 0);
			};
		}
	end;

	["Defeated"]=function(message, player)
		return {
			Message=message;
			ExtraData={
				ChatColor=Color3.fromRGB(255, 102, 0);
				Font = Enum.Font.ArialBold;
			};
		}
	end;
	
	["Important"]=function(message, player)
		return {
			Message=message;
			ExtraData={
				ChatColor=Color3.fromRGB(255, 132, 0);
				Font = Enum.Font.ArialBold;
			};
		}
	end;
	
	["Tier2"]=function(message, player)
		return {
			Message=message;
			ExtraData={
				ChatColor=Color3.fromRGB(51, 102, 204);
			};
		}
	end;
	
	["Tier3"]=function(message, player)
		return {
			Message=message;
			ExtraData={
				ChatColor=Color3.fromRGB(101, 59, 169);
			};
		}
	end;
	
	["Tier4"]=function(message, player)
		return {
			Message=message;
			ExtraData={
				ChatColor=Color3.fromRGB(165, 59, 168);
			};
		}
	end;
	
	["Tier5"]=function(message, player)
		return {
			Message=message;
			ExtraData={
				ChatColor=Color3.fromRGB(107, 51, 51);
			};
		}
	end;
	
	["Tier6"]=function(message, player)
		return {
			Message=message;
			ExtraData={
				ChatColor=Color3.fromRGB(157, 82, 32);
			};
		}
	end;
	
	["Alpha Tester"]=function(message, player)
		return {
			Message=message;
			ExtraData={
				ChatColor=Color3.fromRGB(147,109,231);
			};
		}
	end;
	
	["Staff"]=function(message, player)
		return {
			Message=message;
			ExtraData={
				ChatColor=Color3.fromRGB(206,107,225);
			};
		}
	end;
	
	["Founder"]=function(message, player)
		return {
			Message=message;
			ExtraData={
				ChatColor=Color3.fromRGB(231,186,115);
			};
		}
	end;
};

return NotificationsLibrary;