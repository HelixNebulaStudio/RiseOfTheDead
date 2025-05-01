---
tags:
  - concept
  - rework
---

### Flee (Chance: 20%)
- Reasons:
	- Low Health: `CurHealth <= 10%`
	- No equippable weapon.
- Actions:
	- Run from threat: `EnemyClass`
### Fight
- Reasons:
	- Taken damage recently:  `LastDamageTaken`
	- Visible Threat:  `EnemyClass`  `IsInVision`
- Actions:
	- Fire at/Attack target
	- Alert Nearby: `If AllyClass InRange has WalkieTalkie`
### Alert
- Reasons:
	- Gun fire nearby
	- Spotted dead ally
- Actions:
	- Equip weapon
	- Seek/Investigate: `UnusualNoisePosition`
### Idle
- Reasons:
	- Out of combat long enough: `LastAlertTick`
	- No hostile signs: `!EnemyClass`
- Actions:
	- Patrol
	- Interact with environment: `If Tasks`
	- Heal: `CurHealth <= MaxHealth`
	- Heal Nearby: `If AllyClass & !Healing`

#### Patrol
1. Walk from point A to point B.
2. Report into `walkietalkie` all clear.
3. Repeat