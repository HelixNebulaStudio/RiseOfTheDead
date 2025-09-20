---
tags:
  - completed
  - game_mechanics
  - quality_of_life
---
The Item Stats Window now has a new tab that shows a breakdown of the modifications on your item, from base modifiers to attached modifiers and passive modifiers from other items.

The modifiers applied to each stat is order based on the attached order shown in the workbench.

It first shows the stat name, and base value. E.g. **Damage: 25** or **PreModDamage: ~**, **~** meaning there is no base value.

- The modifiers without a prefix before the value means it overrides any value to the new value. E.g. **[Potential]** overrides **Damage=25 to 42.267**.
- The modifier with "**+**" symbol adds previous value with the new value. E.g. Damage from 42.267 **+8.838**.
- The modifier with "**\***" symbol multiplies previous value with the new value.
- The modifier with "**max/min()**" means it picks the larger/smaller value.

The final value is shown as the last entry. E.g. **Damage = 51.105**.


![[itemStatsWindowModifiersBreakdown.png]]