type notifyTypes = "Inform" | "Positive" | "Negative" | "Reward" | "Message" | "Important";
export type anydict = {[any]: any};

--MARK: shared
declare shared: {
    MasterScriptInit: boolean,

    IsNan: (number) -> boolean,
    Notify: (player: Player, message: string, notifyTypes: notifyTypes) -> nil,

    modPlayers: PlayerClasses,
    modProfile: Profiles,
    modCommandsLibrary: CommandsLibrary,
    modStorage: Storages,
    modPlayerEquipment: PlayerEquipment
}

--MARK: Debugger
export type Debugger = {
    AwaitShared: (string) -> nil;
    Expire: (Instance, number?) -> nil;
    new: (ModuleScript) -> Debugger;

    Require: (self: Debugger, ModuleScript, boolean?) -> any;
    Ray: (self: Debugger, Ray, BasePart?, Vector3?, Vector3?) -> BasePart;
    Point: (self: Debugger, (CFrame | Vector3), Instance) -> Attachment;
    PointPart: (self: Debugger, (CFrame | Vector3)) -> BasePart;

    Stringify: (self: Debugger, ...any) -> string;
    StudioLog: (self: Debugger, ...any) -> nil;
    StudioWarn: (self: Debugger, ...any)  -> nil;
    Warn: (self: Debugger, ...any) -> nil;

    Debounce: (self: Debugger, string, number) -> boolean;
}

--MARK: GarbageHandler
export type GarbageHandler = {
    ClassName: string;
    Trash: {[any]:any};
    new: () -> GarbageHandler;

    Tag: (self:GarbageHandler, item: any) -> nil;
    Untag: (self:GarbageHandler, item: any) -> nil;
    Loop: (self:GarbageHandler, loopFunc: ((index: number, trash: any) -> boolean?) ) -> nil;
    Destruct: (self:GarbageHandler) -> nil;
}

--MARK: EventSignal
export type EventSignal = {
	Name: string?;
	Functions: {[number]: (...any)->(...any)};
} & {
    new: (name: string?) -> EventSignal;
    Fire: (self: EventSignal, ...any) -> nil;
    Wait: (self: EventSignal, timeOut: number?) -> ...any;
    Connect: (self: EventSignal, func: (...any) -> ...any) -> (() -> nil);
    Disconnect: (self: EventSignal, func: any) -> nil;
    Once: (self: EventSignal, func: (...any)-> ...any) -> (() -> nil);
    Destroy: (self: EventSignal) -> nil;
    DisconnectAll: (self: EventSignal) -> nil;
};

--MARK: Profiles
export type Profiles = {
    Get: (self: Profiles, player: Player) -> Profile;
    Find: (self: Profiles, playerName: string) -> Profile;
    [any]: any;
};

export type Profile = {
    Player: string;
    UserId: number;

    Garbage: GarbageHandler;

    GameSave: GameSave;
} & Profiles;


--MARK: GameSave
export type GameSave = {
    Inventory: Storage;
    Clothing: Storage;
};


--MARK: Storage
export type Storages = {
    GetPrivateStorages: (player: Player) -> {[string]: Storage};
    Get: (id: string, player: Player) -> Storage?;
    FindIdFromStorages: (siid: string, player: Player) -> (StorageItem?, Storage?);
    FindItemIdFromStorages: (itemId: string, player: Player) -> (StorageItem?, Storage?);
    ListItemIdFromStorages: (itemId: string, player: Player, storageIdSearchList: {string}) -> (
        {Item: StorageItem, Storage: Storage}, 
        number
    );
};

export type Storage = {
    Id: string;
    Name: string;
    Size: number;
    ViewOnly: boolean;

    Container: {[string]: StorageItem};

    Find: (id: string) -> StorageItem;
};

--MARK: StorageItem
export type StorageItem = {
    ID: string;
    ItemId: string;
    Player: Player;
    Library: {[string]: any};
    Values: {[string]: any};
    Quantity: number;
}


--MARK: PlayerClass
export type PlayerClasses = {
    Get: (Player) -> PlayerClass;
};

export type PlayerClass = CharacterClass & {
    Name: string;

    IsAlive: boolean;
    IsUnderWater: boolean;
    IsSwimming: boolean;

    MaxOxygen: number;

    CharacterModule: {[any]: any};
    Configurations: ConfigVariable;
    Properties: {[any]: any};

    LastDamageTaken: number;
    LastDamageDealt: number;
    LastArmorDamageTaken: number;
    LastHealed: number;

    LowestFps: number;
    AverageFps: number;

    IsTeleporting: boolean;
    TeleportPlaceId: number;

    Invisible: boolean;
    CurrentState: Enum.HumanoidStateType;

    OnDamageTaken: EventSignal;
    OnHealthChanged: EventSignal;
    OnIsAliveChanged: EventSignal;
    OnCharacterSpawn: EventSignal;
    Died: EventSignal;

    Spawn: (self: PlayerClass) -> nil;
    Kill: (self: PlayerClass, reason: string?) -> nil;
    GetInstance: (self: PlayerClass) -> Player;
    SetProperties: (self: PlayerClass, key: string, value: any) -> nil;
    SyncProperty: (self: PlayerClass, key: string) -> nil;
    GetCFrame: (self: PlayerClass) -> CFrame;

    GetStatus: (self: PlayerClass, statusId: string) -> StatusClass;
    SyncStatus: (self: PlayerClass, statusId: string) -> nil;
    ListStatus: (self: PlayerClass) -> {StatusClass};

    SetHealSource: (self: PlayerClass, srcId: string?, packet: ({[any]: any})?) -> nil;
    SetArmorSource: (self: PlayerClass, srcId: string?, packet: ({[any]: any})?) -> nil;
    RefreshHealRate: (self: PlayerClass) -> nil;

    GetEquippedTools: (self: PlayerClass) -> {ItemId: string};
    UnequipTools: (self: PlayerClass) -> nil;

    SyncIsAlive: (self: PlayerClass) -> nil;
    OnConfigurationsCalculate: (self: PlayerClass) -> nil;
    OnNotIsAlive: (self: PlayerClass, func: (character: Model)-> nil) -> nil;

    OnDeathServer: (self: PlayerClass)->nil;
    OnCharacterAdded: (character: Model)->nil;
    OnPlayerTeleport: ()->nil;
};

--MARK: CharacterClass
export type CharacterClass = {
    ClassName: string;

    Character: Model;
    Humanoid: Humanoid;
    RootPart: BasePart;
    Head: BasePart;

    HealthComp: HealthComp;
    GetHealthComp: (self: CharacterClass, bodyPart: BasePart) -> HealthComp?;

    Configurations: anydict;
    Initialize: () -> nil;
};

--MARK: StatusClass
export type StatusClass = {
    ClassName: string;

    Instance: (self: StatusClass) -> StatusClassInstance;

    OnApply: ((self: StatusClass) -> nil);
    OnExpire: ((self: StatusClass) -> nil);
    OnTick: ((self: StatusClass, tickData: TickData) -> nil);
    OnRelay: ((self: StatusClass) -> nil);
};

export type StatusClassInstance = {
    StatusComp: StatusComp;
    Garbage: GarbageHandler;
    
    Values: anydict;
    IsExpired: boolean;

    Expires: number?;
    ExpiresOnDeath: boolean?;
    Duration: number?;
} & StatusClass;

--MARK: NpcClass
export type NpcClass = CharacterClass & {
    StatusComp: StatusComp;

    GetImmunity: (self: NpcClass, damageType: string?, damageCategory: string?) -> number; 
    Status: any;
    Properties: anydict;
    CustomHealthbar: anydict;
    KnockbackResistant: any;
    BleedResistant: any;
    SpawnTime: number;
    Detectable: boolean;
};

--MARK: Interactables
export type Interactables = {
    new: (ModuleScript, Model?) -> (Interactable, InteractableMeta);
    [any]: any;
}

export type Interactable = {
    CanInteract: boolean;
    Type: string;
    [any]: any;
}

export type InteractableMeta = {
    Label: string,
    [any]: any
}

--MARK: InterfaceClass
export type InterfaceClass = {
    TouchControls: Frame;
    HintWarning: (self: InterfaceClass, label: string) -> nil;
    ToggleWindow: (self: InterfaceClass, windowName: string, visible: boolean) -> nil;
};

--MARK: ToolHandler
export type ToolHandler = {
    ClassName: string;
    Handlers: {[string]: any};
    
    loadTypeHandler: (ModuleScript) -> any;
    getTypeHandler: (string) -> any?;
    new: () -> ToolHandler,
    Instance: (self: ToolHandler) -> ToolHandlerInstance;
    Destroy: (self: ToolHandler) -> ();

    OnInit: (self: ToolHandlerInstance) -> nil;

    OnClientEquip: (self: ToolHandlerInstance) -> nil;
    OnClientUnequip: (self: ToolHandlerInstance) -> nil;

    OnActionEvent: (self: ToolHandlerInstance, packet: {[any]: any}) -> nil;
    OnInputEvent: (self: ToolHandlerInstance, inputData: {[any]: any}) -> nil;

    OnServerEquip: (self: ToolHandlerInstance) -> nil;
    OnServerUnequip: (self: ToolHandlerInstance) -> nil;
}

export type ToolHandlerInstance = {
    CharacterClass: CharacterClass;

    Binds: {[any]: any};
    Garbage: GarbageHandler;

    StorageItem: StorageItem;
    ToolPackage: {[any]: any};
    ToolAnimator: ToolAnimator;

    Prefabs: {[number]: Model};
    EquipmentClass: EquipmentClass;
}

export type ToolAnimator = {
    Play: (
        self: ToolAnimator, 
        animKey: string, 
        param: ({
            FadeTime: number?;
            PlaySpeed: number?;
            PlayLength: number?;
            PlayWeight: number?;
            [any]: any;
        })?
    ) -> AnimationTrack;
    Stop: (self: ToolAnimator,
        animKey: string,
        param: ({
            FadeTime: number?
        })?
    ) -> nil;
    GetPlaying: (self: ToolAnimator, animKey: string) -> AnimationTrack;
    GetKeysPlaying: (self: ToolAnimator, animKeys: {string}) -> {[string]: AnimationTrack};
    LoadToolAnimations: (self: ToolAnimator, animations: {[any]: any}, state: string, prefabs: {Model}) -> nil;
    GetTracks: (self: ToolAnimator, animKey: string) -> {AnimationTrack};
    ConnectMarkerSignal: (self: ToolAnimator, markerKey: string, func: ((animKey: string, track: AnimationTrack, value: any)->nil)) -> nil;
};


--MARK: ConfigVariable
export type ConfigVariable = {
    BaseValues: {[any]: any};
    FinalValues: {[any]: any};
    Modifiers: {ConfigModifier};

    GetKeyPairs: (self: ConfigVariable) -> {[any]: any};
    GetBase: (self: ConfigVariable, key: string) -> any;
    GetFinal: (self: ConfigVariable, key: string) -> any;

    Calculate: (self: ConfigVariable, baseValues: {any}?, modifiers: {any}?, finalValues: {any}?) -> {any};

    GetModifier: (self: ConfigVariable, id: string) -> (number?, ConfigModifier?);
    AddModifier: (self: ConfigVariable, modifier: ConfigModifier, recalculate: boolean?) -> nil;
    RemoveModifier: (self: ConfigVariable, id: string, recalculate: boolean?) -> ConfigModifier?;

    newModifier: (id: string) -> ConfigModifier;

    [string]: any;
};

export type ConfigModifier = {
    Id: string;
    Priority: number;
    Tags: anydict;
    Values: anydict; 

    BaseValues: anydict;
    SetValues: anydict;
    SumValues: anydict;
    ProductValues: anydict;
    MaxValues: anydict;
    MinValues: anydict;
};

--MARK: EquipmentClass
export type EquipmentClass = {
    Enabled: boolean;
    SetEnabled: (self: EquipmentClass, value: boolean) -> nil;

    Class: string;
    Configurations: ConfigVariable;
    Properties: {[any]: any};

    Update: (self: EquipmentClass, storageItem: StorageItem?) -> nil;
    AddModifier: (self: EquipmentClass, modifierId: string, config: {
        BaseValues: anydict?;
        SetValues: anydict?;
        SumValues: anydict?;
        ProductValues: anydict?;
        MaxValues: anydict?;
        MinValues: anydict?;
    }) -> nil;
    [any]: any;
};


--MARK: CommandsLibrary
export type CommandsLibrary = {
    PermissionLevel: {
        All: number;
        ServerOwner: number;
        DevBranch: number;
        Moderator: number;
        Admin: number;
        GameTester: number;
        DevBranchFree: number;
    };

    HookChatCommand: (self: CommandsLibrary, cmd: string, cmdPacket: {
        Permission: number;
        Description: string;
        RequiredArgs: number?;
        UsageInfo: string?;
        Function: ((speaker: Player, args: {any}) -> boolean)?;
        ClientFunction: ((speaker: Player, args: {any}) -> boolean)?;
    }) -> nil;
};

--MARK: ItemModifier
export type ItemModsLibrary = {
    calculateLayer: (itemModifier: ItemModifier, upgradeKey: string) -> {[any]: any};
};

export type ItemModifier = {
    ClassName: string;
    Library: ItemModsLibrary;

    Tags: {[any]: any};
    Ready: (self: ItemModifierInstance) -> nil;
    Update: (self: ItemModifierInstance) -> nil;
    SetTickCycle: (self: ItemModifierInstance, value: boolean) -> nil;
   
    Sync: (self: ItemModifier, syncKeys: {string}) -> nil;
    Hook: (self: ItemModifier, functionId: string, func: (modifier: ItemModifierInstance, ...any)->nil) -> nil;
};

export type ItemModifierInstance = {
    Script: ModuleScript;

    Enabled: boolean;
    SetEnabled: (self: ItemModifierInstance, value: boolean) -> nil;
    OnEnabledChanged: EventSignal;
    
    Player: Player?;
    ModLibrary: ({any}?);
    EquipmentClass: EquipmentClass?;
    EquipmentStorageItem: StorageItem?;
    ItemModStorageItem: StorageItem?;

} & ItemModifier & ConfigModifier;

--MARK: PlayerEquipment
export type PlayerEquipment = {
    getEquipmentClass: (siid: string, player: Player?) -> EquipmentClass;
    getToolHandler: (storageItem: StorageItem, toolModels: ({Model}?)) -> ToolHandlerInstance;

    getItemModifier: (siid: string, player: Player) -> ItemModifierInstance;
    setItemModifier: (modifierId: string, itemModifier: ItemModifierInstance, player: Player) -> nil;

    getPlayerItemModifiers: (player: Player) -> {ItemModifierInstance};
};

--MARK: Destructible
export type Destructible = {
    ClassName: string;

    HealthComp: HealthComp;
};

--MARK: -- Data Models
-- Data packs that stores values to be passed into functions.
--
--
--
--
--
--MARK: DamageData
export type DamageData = {
    DamageBy: CharacterClass;

    Damage: number;
    DamageType: string;

    Clone: (self: DamageData) -> DamageData;

    DamageTo: CharacterClass?;
    TargetPart: BasePart?;
    DamageCate: string?;
    ToolHandler: ToolHandlerInstance?;
    StorageItem: StorageItem?;
};

export type TickData = {
    Delta: number;
    ms100: boolean;
    ms500: boolean;
    ms1000: boolean;
    s5: boolean;
    s10: boolean;
};

export type StatusCompApplyData = {
    Expires: number?;
    Duration: number?;

    Values: ({
        [any]: any;

        ImmunityReduction: number?;
    })?;
}

export type OnBulletHitPacket = {
    OriginPoint: Vector3;
    
    TargetPart: BasePart;
    TargetPoint: Vector3;
    TargetNormal: Vector3;
    TargetMaterial: Enum.Material;
    TargetIndex: number;
    TargetDistance: number;

    TargetModel: Model;
    IsHeadshot: boolean;
}

--MARK: -- Components
-- Class composition components, with minimal coupling to external code.
--
--
--
--
--
--MARK: HealthComp
export type HealthComp = {
    -- @static
    getFromModel: (model: Model) -> HealthComp;

    OwnerClass: (Destructible | NpcClass | PlayerClass);
    IsDead: boolean;
    
    CurHealth: number;
    MaxHealth: number;
    KillHealth: number;

    CanTakeDamageFrom: (self: HealthComp, characterClass: CharacterClass) -> boolean;    
    TakeDamage: (self: HealthComp, DamageData: DamageData) -> nil;
    
    LastDamagedBy: CharacterClass?;
}

--MARK: StatusComp
type StatusCompEnjoyer = (Destructible | NpcClass | PlayerClass); -- Classes with this component.
export type StatusComp = { 
    OwnerClass: StatusCompEnjoyer;

    Apply: (self: StatusComp, key: string, value: StatusCompApplyData) -> StatusClassInstance;
    GetOrDefault: (self: StatusComp, key: string, value: anydict?) -> StatusClassInstance;
};