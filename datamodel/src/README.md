Revive Engine source code is located here and is closed source.


Recent changes to code in Engine codebase:
- Added TextSizes ref for interface auto scale.
- Fixed locked out Npcs (e.g. Frank & Jesse) from certain doors.
- Fixed Instrument Interface. [#1135] [#1136]
- Fixed April Fool's initial dialogue spam. [#1130] [#1111]
- Fixed npc immunity not being factored into damage calculations. [#1141] [#1168] [#1142]
- Fixed Hide Hud toggle. [#1169]
- Fixed Pat reload breaking. [#1154]
- Fixed guns not auto reloading. [#1112]
- Improved Melee input responsiveness. Throwable melees no longer can primary attack if holding down focus. [#1118] [#1139]
- Fixed tools input handling.
- Fixed set vanity option not opening Wardrobe properly.
- Fixed favorite item not syncing to client. [#990]
- Fixed `snowsledge` not activating on slide. [#994]
- Fixed npcs keeping idle stance when firing weapons. [#1029]
- Fixed Bosses not aggro-ing player if they do not have a npc following them. [#1031]
- Fixed `Pickupable` interactables missing notification and not visible when inventory is full. [#1040]
- Fixed `molotov`, `broomspear`, `fireworks` and `snowball` not checking if target can take damage. [#1093] [#1092]
- Fixed projectile not using correct variable for lifetime [#1095]
- Fixed some weapons having collidable parts. [#1077]
- Fixed Storage.Properties being a public table instead of private. [#1080]
- Fixed duplicated explosion forces when applied to npc body destructibles. [#1036]
- Fixed HealTool handling heal request when interactable is available. [#1017]
- Fixed InterfaceClass now properly creating dropdown options. [#1064]
- Fixed Toxic damage type handling missing damageBy value. [#1010]
- Fixed skins and customizations not loading with new equipment system.
- Fixed calculation errors in volume settings.
- Fixed TargetDummy missing destructible.
- Fixed item description not checking equipment configurations and properties.
- Disabled client game events relaying to server by default.
- Fixed collision groups of Players and Debris colliding.