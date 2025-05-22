export type GAME_EVENT_KEY_ROTD =
    | "EventPass_OnLevelUp"
    | "EventPass_PuzzleInvoke"
    | "GameModeManager_DisconnectPlayer"
    | "Skills_OnResourceGatherers"
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
    | "Zombie"
    | "Bandit"
    | "Rat"
    | "Cultist"
    | "Military"
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
    Masteries: anydict;
    Blueprints: anydict;
}

--MARK: EquipmentClass
export type EquipmentClassRotd = EquipmentClass & {
    [any]: any;
};
