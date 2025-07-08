export type GAME_EVENT_KEY_ROTD =
    | "EventPass_BindLevelUp"
    | "EventPass_BindPuzzleInvoke"
    | "GameModeManager_BindDisconnectPlayer"
    | "Dialogue_BindMedicHeal"
    | "Skills_BindResourceGatherers"
    | "Shop_BindActionEvent"
    | "WorkbenchService_BindInterfaceToggle"
    | "WorkbenchService_BindItemSelect"
    ;

export type DAMAGE_TYPE_ROTD =
    | "Bleed"
    | "Crit"
    | "Explosive"
    | "Fire"
    | "Frost"
    | "Electric"
    | "Toxic"
    | "Thorn"
    ;

export type HUMANOID_TYPE_ROTD =
    | "Bandit"
    | "Cultist"
    | "Military"
    | "Rat"
    | "Zombie"
    ;

--MARK: ProfileRotd
export type ProfileRotd = Profile & {
    SkillTree: anydict;
    ItemUnlockables: anydict;
    Trader: anydict;
    Safehome: anydict;
    BattlePassSave: anydict;
    NpcTaskData: anydict;
    Faction: anydict;
}

--MARK: GameSaveRotd
export type GameSaveRotd = GameSave & {
    Spawn: string;
    
    Wardrobe: Storage;
    Masteries: anydict;
    Blueprints: anydict;
}

--MARK: EquipmentClass
export type EquipmentClassRotd = EquipmentClass & {
};


--MARK: 