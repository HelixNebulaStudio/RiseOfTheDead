export type anydict = {[any]: any};

-- constant uniontypes
export type GAME_EVENT_KEY<U> = U
    | "Crates_OnSpawn"
    | "Generic.OnClockTick"
    | "Generic_OnItemPickup"
    | "Interactables_OnTrigger"
    | "Npcs.OnEnemiesAttract"
    | "Npcs_OnDamaged"
    | "Players_OnSpawn"
    | "Players_OnDamaged"
    | "Players_OnHeal"
    | "Profile_OnPlayPoints"
    | "Players_OnWieldEvent"
    | "Tools_OnHealTool"
    | "WeatherService.OnWeatherSet"
    ;

export type NOTIFY_TYPE =
    | "Inform"
    | "Important"
    | "Message" 
    | "Negative" 
    | "Positive" 
    | "Reward" 
    ;

export type DAMAGE_TYPE<U> = U
    | "Armor"
    | "ArmorOnly"
    | "Heal"
    | "IgnoreArmor"
    ;

export type HUMANOID_TYPE<U> = U
    | "Human"
    | "Player"
    ;

--MARK: shared
declare shared: {
    -- @engine globals
    IsMainThread: boolean;
    EngineIgnited: boolean;

    ReviveEngineLoaded: boolean;
    MasterScriptInit: boolean;
    Const: Const;

    waitForIgnition: ()->nil;
    igniteEngine: ()->nil;

    require: (moduleScript: ModuleScript | string, ...any) -> any;
    saferequire: (player: Player, moduleScript: ModuleScript) -> any;
    getI: (path: string) -> Instance?;

    gameCore: string?;
    coreCall: (class: anydict, key: string, ...any) -> any;
    coreBind: (class: anydict, key: string, func: (...any)->...any) -> any;

    -- @system globals
    IsNan: (number) -> boolean;
    Notify: (player: Player, message: string, notifyTypes: NOTIFY_TYPE) -> nil;

    -- @game globals
    EventSignal: EventSignal<>;
    modPlayers: PlayerClasses;
    modProfile: Profiles;
    modCommandsLibrary: CommandsLibrary;
    modStorage: Storages;
    modNpcs: NpcClasses;
    modEventService: EventService;
    modEngineCore: EngineCore;
};

--MARK: Const
export type Const = {
    Hour: number;
    Hours20: number;

    OneDaySecs: number;
    WeekSecs: number;
    MonthSecs: number;
}

--MARK: EngineCore
export type EngineCore = {
    ConnectOnPlayerAdded: (self: EngineCore, src: Script | LocalScript | ModuleScript, func: (...any)->...any, order: number?) -> nil;
};

--MARK: Class
export type Class = {
    Script: LuaSourceContainer;
} & anydict;

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
export type EventSignal<T...> = {
	Name: string?;
	Functions: {(T...)->(...any)};
} & {
    new: (name: string?) -> EventSignal<T...>;
    Fire: (self: EventSignal<T...>, ...any) -> nil;
    Wait: (self: EventSignal<T...>, timeOut: number?) -> ...any;
    Connect: (self: EventSignal<T...>, func: (T...) -> ...any) -> (() -> nil);
    Disconnect: (self: EventSignal<T...>, func: any) -> nil;
    Once: (self: EventSignal<T...>, func: (T...)-> ...any) -> (() -> nil);
    Destroy: (self: EventSignal<T...>) -> nil;
    DisconnectAll: (self: EventSignal<T...>) -> nil;
};

--MARK: EventPacket
export type EventPacket = {
    Key: GAME_EVENT_KEY<string>;
    Source: number;

    Cancelled: boolean;
    Completed: boolean;

    Player: Player?;
    Players: {[number]: Player}?;
}

--MARK: EventService
export type EventService = {
    ClientInvoke: (
        self: EventService, 
        key: GAME_EVENT_KEY<string>, 
        invokeParam: EventInvokeParam, 
        ...any?
    ) -> EventPacket;
    ServerInvoke: (
        self: EventService, 
        key: GAME_EVENT_KEY<string>, 
        invokeParam: EventInvokeParam, 
        ...any?
    ) -> EventPacket;
    OnInvoked: (
        self: EventService, 
        key: GAME_EVENT_KEY<string>, 
        (event: EventPacket, ...any) -> nil, 
        position: number?
    ) -> (()->nil);
};


--MARK: Profiles
export type Profiles = {
    -- @static
    new: (player: Player) -> Profile;

    -- @methods
    Get: (self: Profiles, player: Player) -> Profile;
    Find: (self: Profiles, playerName: string) -> Profile;
};

export type Profile = {
    -- @properties
    Player: Player;
    UserId: number;

    Garbage: GarbageHandler;

    GameSave: GameSave;
    ActiveGameSave: GameSave;

    Premium: boolean;
    GamePass: anydict;

    Cache: anydict;
    
    -- @methods
    Sync: (self: Profile, hierarchyKey: string?, paramPacket: anydict?) -> nil;

    -- @coreBinds
    _new: (self: Profile, player: Player) -> nil;
    _key_load: (self: Profile, key: string, data: any, loadOverwrite: anydict?) -> boolean; -- handled if true;
    _reset_save: (self: Profile) -> nil;
    _sync: (self: Profile, hierarchyKey: string?, paramPacket: anydict?) -> nil;
    _save: (self: Profile, overrideData: any?, force: boolean?) -> nil;
    _sync_public: (self: Profile, publicData: anydict, caller: Player) -> nil;
} & Profiles;


--MARK: GameSave
export type GameSave = {
    Inventory: Storage;
    Clothing: Storage;

    -- @methods
    Sync: (self: GameSave, hierarchyKey: string?) -> nil;

    -- @coreBinds
    _new: (gameSave: GameSave, profile: Profile) -> nil;
};


--MARK: Storage
export type Storages = {
    GetPrivateStorages: (player: Player) -> {[string]: Storage};
    Get: (id: string, player: Player) -> Storage?;
    FindIdFromStorages: (siid: string, player: Player) -> (StorageItem?, Storage?);
    FindItemIdFromStorages: (itemId: string, player: Player) -> (StorageItem?, Storage?);
    ListItemIdFromStorages: (itemId: string, player: Player, storageIdSearchList: {string}) -> (
        {{Item: StorageItem, Storage: Storage}}, 
        number
    );
    RemoveItemIdFromStorages: (itemId: string, player: Player, amount: number, storageIdSearchList: {string}) -> nil;
    
    -- @signals
    OnItemSourced: EventSignal<Storage, StorageItem, number>;
};

export type Storage = {

    -- @properties
    Id: string;
    Name: string;

    Size: number;
    MaxSize: number;
    PremiumStorage: number;

    ViewOnly: boolean;

    Container: {[string]: StorageItem};
    LinkedStorages: anydict;

    -- @methods
    Find: (self: Storage, id: string) -> StorageItem;
    InsertRequest: (self: Storage, storageItem: StorageItem, ruleset: anydict?) -> anydict;
    Sync: (self: Storage, player: Player) -> nil;

    -- @signals
    OnChanged: EventSignal<>;
};

--MARK: StorageItem
export type StorageItem = {
    -- @properties
    ID: string;
    ItemId: string;
    Player: Player;
    Storage: Storage;
    Library: {[string]: any};
    Values: {[string]: any};
    Quantity: number;
    IsFake: boolean;
    
    -- @methods
    Sync: (self: StorageItem, keys: {string}?) -> nil;
    GetValues: (self: StorageItem, key: string) -> any;
    SetValues: (self: StorageItem, key: string, value: any?, syncFunc: any?) -> StorageItem;
}


--MARK: PlayerClass
export type PlayerClasses = {
    -- @static
    get: (Player) -> PlayerClass;
    
    -- @signals
    OnPlayerDied: EventSignal<PlayerClass>;
};

export type PlayerClass = CharacterClass & {
    -- @properties
    Name: string;

    IsAlive: boolean;
    IsUnderWater: boolean;
    IsSwimming: boolean;

    MaxOxygen: number;

    CharacterVars: anydict;
    Configurations: ConfigVariable;
    Properties: anydict;

    LastDamageDealt: number;
    LastHealed: number;

    LowestFps: number;
    AverageFps: number;

    IsTeleporting: boolean;
    TeleportPlaceId: number;

    Invisible: boolean;
    CurrentState: Enum.HumanoidStateType;

    -- @methods
    Spawn: (self: PlayerClass) -> nil;
    Kill: (self: PlayerClass, reason: string?) -> nil;
    GetInstance: (self: PlayerClass) -> Player;
    
    GetCFrame: (self: PlayerClass) -> CFrame;
    SetCFrame: (self: PlayerClass, cframe: CFrame) -> CFrame;

    SyncProperty: (self: PlayerClass, key: string, players: any) -> nil;

    RefreshHealRate: (self: PlayerClass) -> nil;

    SyncIsAlive: (self: PlayerClass) -> nil;
    OnConfigurationsCalculate: (self: PlayerClass) -> nil;
    OnNotIsAlive: (self: PlayerClass, func: (character: Model)-> nil) -> nil;

    OnDeathServer: (self: PlayerClass)->nil;
    OnCharacterAdded: (character: Model)->nil;
    OnPlayerTeleport: ()->nil;
    
    -- @signals
    OnDamageTaken: EventSignal<any>;
    OnHealthChanged: EventSignal<any>;
    OnIsAliveChanged: EventSignal<any>;
    OnCharacterSpawn: EventSignal<any>;
    Died: EventSignal<any>;
};

--MARK: CharacterClass
export type CharacterClass = {
    -- @properties
    ClassName: "PlayerClass" | "NpcClass";

    Name: string;
    Character: Model;
    Humanoid: Humanoid;
    HumanoidType: HUMANOID_TYPE<string>;
    RootPart: BasePart;
    Head: BasePart;
    
    Configurations: ConfigVariable;
    Properties: anydict;

    Garbage: GarbageHandler;

    HealthComp: HealthComp;
    StatusComp: StatusComp;
    WieldComp: WieldComp;

    -- @methods
    GetHealthComp: (self: CharacterClass, bodyPart: BasePart) -> HealthComp?;
    Kill: (self: CharacterClass) -> nil;

    Initialize: () -> nil;
};

--MARK: StatusClass
type StatusPackage = {
    Id: string;
    Icon: string;
    Name: string;
    Description: string;
    Buff: boolean;
    Tags: {string};
    PresistUntilExpire: anydict;
    ExpiresOnDeath: boolean;
};

export type StatusClass = {
    ClassName: string;

    Instance: (self: StatusClass) -> StatusClassInstance;

    OnApply: (self: StatusClassInstance) -> nil;
    OnUpdate: (self: StatusClassInstance) -> nil;
    OnExpire: (self: StatusClassInstance) -> nil;
    OnTick: (self: StatusClassInstance, tickData: TickData) -> nil;
    OnRelay: (self: StatusClassInstance, ...any) -> nil;
} & StatusPackage;

export type StatusClassInstance = {
    -- @properties
    Uid: string;
    StatusComp: StatusComp;
    StatusOwner: ComponentOwner;

    Garbage: GarbageHandler;
    
    Visible: boolean;
    IsExpired: boolean;
    Values: anydict;

    Expires: number?;
    ExpiresOnDeath: boolean?;
    Duration: number?;
    Alpha: number?;

    
    -- @methods
    Sync: (self: StatusClassInstance, players: any)->nil; --Server to Client
    Relay: (self: StatusClassInstance, ...any)->nil; --Client to Server
    Shrink: (self: StatusClassInstance) -> anydict;
} & StatusClass;

--MARK: NpcClasses
export type NpcClasses = {
    -- @static
    ActiveNpcClasses: {NpcClass};
    NpcBaseConstructors: anydict;

    getByModel: (Model) -> NpcClass?;
    getById: (number) -> NpcClass?;
    getByOwner: (player: Player, npcName: string) -> NpcClass?;
    listNpcClasses: (matchFunc: (npcClass: NpcClass) -> boolean) -> {NpcClass};
    listInRange: (origin: Vector3, radius: number, maxRootpart: number?) -> {NpcClass};
    attractNpcs: (model: Model, range: number, func: ((npcClass: NpcClass)-> boolean)? ) -> {Model};

    getNpcPrefab: (npcName: string) -> Model;
    spawn: (
        npcName: string, 
        cframe: CFrame?, 
        preloadCallback: ((prefab: Model, npcClass: NpcClass) -> Model)?, 
        customNpcClassConstructor: any?, 
        customNpcPrefab: (Model)?
    ) -> Model;
    spawn2: ({
        Name: string;
        CFrame: CFrame?;

    }) -> NpcClass;
    
    -- @signals
    OnNpcSpawn: EventSignal<NpcClass>;
};

--MARK: NpcClass
export type NpcClass = CharacterClass & {
    -- @properties
    Id: number;
    Actor: Actor?;
    SpawnPoint: CFrame?;
    IsReady: boolean;

    Owner: Player?;
    NetworkOwners: {Player};

    BehaviorTree: anydict;
    PathAgent: anydict;

    NpcPackage: anydict;
    NpcComponentsList: {string};
    
    Storages: {[string]: Storage};

    Interactable: ModuleScript?;
    
    -- @methods
    Setup: (self: NpcClass, baseNpcModel: Model, npcModel: Model) -> nil;
    Destroy: (self: NpcClass) -> nil;
    TeleportHide: (self: NpcClass) -> nil;

    AddComponent: (self: NpcClass, component: string | ModuleScript) -> nil;
    GetComponent: (self: NpcClass, componentName: string) -> any;
    ListComponents: (self: NpcClass) -> {any};
    
    SetCFrame: (self: NpcClass, cframe: CFrame, angle: CFrame) -> nil;
    IsInVision: (self: NpcClass, object: BasePart, fov: number?) -> boolean;
    DistanceFrom: (self: NpcClass, pos: Vector3) -> number;
    ToggleInteractable: (self: NpcClass, v: boolean) -> nil;

    -- @signals
    OnThink: EventSignal<any>;

    -- @components
    SetAnimation: (animName: string, animList: {Animation}) -> nil;
    GetAnimation: (animName: string) -> AnimationTrack?;
    PlayAnimation: (animName: string, ...any) -> AnimationTrack; 
    StopAnimation: (animName: string, ...any) -> nil;
    Move: anydict;


    -- @dev
    GetImmunity: (self: NpcClass, damageType: string?, damageCategory: string?) -> number; 
    Status: any;
    CustomHealthbar: anydict;
    KnockbackResistant: any;
    BleedResistant: any;
    SpawnTime: number;
    Detectable: boolean;
    AnimationController: anydict;
    JointRotations: anydict;
};

--MARK: Interactables
export type Interactables = {
    new: (ModuleScript, Model?) -> (InteractableInstance, InteractableMeta);
    register: (name: string, package: anydict) -> nil;

    Instance: (name: string, scr: ModuleScript, ...any) -> InteractableInstance;
}

export type InteractableMeta = {
    Name: string;
    Type: string;
    Label: string;
    TouchInteract: boolean; 
    IndicatorPresist: boolean;
    InteractableRange: number;
}

export type InteractableInstance = {
    -- @properties
    Script: ModuleScript;
    Prefab: Instance?;
    Object: BasePart;

    CanInteract: boolean;
    Values: anydict;

    Label: string?;

    -- @methods
    ActionEvent: ((info: InteractInfo) -> nil)?;
    PromptEvent: ((info: InteractInfo) -> nil)?;
} & InteractableMeta;

export type InteractInfo = {
    ActionTypes: {
        ClientInteract: string;
        ServerInteract: string;
    };
    Values: anydict;

    Action: string?;
    Player: Player?;

    -- @client
    ClientData: anydict?;
    ClientInterface: anydict?;
    CharacterVars: anydict?;
};

--MARK: InterfaceClass
export type InterfaceClass = {
    TouchControls: Frame;
    HintWarning: (self: InterfaceClass, label: string) -> nil;
    ToggleWindow: (self: InterfaceClass, windowName: string, visible: boolean) -> nil;
};

--MARK: ToolHandler
export type ToolHandler = {
    -- @static
    onRequire: ()->nil;
    loadTypeHandler: (ModuleScript) -> any;
    getTypeHandler: (string) -> any?;
    new: () -> ToolHandler;
    
    -- @properties
    ClassName: string;
    Handlers: {[string]: any};
   
    -- @methods
    Instance: (self: ToolHandler) -> ToolHandlerInstance;
    Destroy: (self: ToolHandler) -> ();
    PlayAudio: (self: ToolHandler, audioName: string, parent: Instance, playFunc: ((sound: Sound, audioInfo: anydict)->nil)?) -> Sound?;
    LoadWieldConfig: (self: ToolHandler) -> nil;

    Init: (toolHandler: ToolHandlerInstance) -> nil;
    Setup: (toolHandler: ToolHandlerInstance) -> nil;

    ClientEquip: (toolHandler: ToolHandlerInstance) -> nil;
    ClientUnequip: (toolHandler: ToolHandlerInstance) -> nil;

    ActionEvent: (toolHandler: ToolHandlerInstance, packet: {[any]: any}) -> nil;
    InputEvent: (toolHandler: ToolHandlerInstance, inputData: {[any]: any}) -> nil;

    ServerEquip: (toolHandler: ToolHandlerInstance) -> nil;
    ServerUnequip: (toolHandler: ToolHandlerInstance) -> nil;
};

export type ToolHandlerInstance = {
    -- @properties
    CharacterClass: CharacterClass;
    WieldComp: WieldComp;

    StorageItem: StorageItem;
    ToolPackage: anydict;
    EquipmentClass: EquipmentClass;
    Garbage: GarbageHandler;

    Prefabs: {[number]: Model};
    ToolGrips: {[number]: Motor6D};
    Binds: anydict;

    ToolAnimator: ToolAnimator;
    -- AnimGroup: anydict;
} & ToolHandler;

export type GunToolHandler = ToolHandler & {
    FireWeapon: (toolHandler: GunToolHandlerInstance, direction: Vector3, enemyHumanoid: Humanoid?) -> nil;
    PrimaryFireRequest: (toolHandler: GunToolHandlerInstance, direction: Vector3, enemyHumanoid: Humanoid?) -> nil;
    ReloadRequest: (toolHandler: GunToolHandlerInstance) -> nil;
    ToggleIdle: (toolHandler: GunToolHandlerInstance, value: boolean) -> nil;
    [any]: any;
};
export type GunToolHandlerInstance = ToolHandlerInstance & GunToolHandler;

export type ToolAnimator = {
    Play: (
        self: ToolAnimator, 
        animName: string, 
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
    StopAll: (self: ToolAnimator)->nil;

    GetPlaying: (self: ToolAnimator, animKey: string) -> AnimationTrack;
    GetKeysPlaying: (self: ToolAnimator, animKeys: {string}) -> {[string]: AnimationTrack};
    LoadAnimations: (self: ToolAnimator, animations: anydict, default: string, prefabs: {Model}) -> nil;
    ConnectMarkerSignal: (self: ToolAnimator, markerKey: string, func: ((animKey: string, track: AnimationTrack, value: any)->nil)) -> nil;

    Init: (...any)->nil;
};


--MARK: ConfigVariable
export type ConfigVariable = {
    -- @static
    newModifier: (id: string) -> ConfigModifier;

    -- @properties
    BaseValues: {[any]: any};
    FinalValues: {[any]: any};
    Modifiers: {ConfigModifier};

    -- @methods
    GetKeyPairs: (self: ConfigVariable) -> {[any]: any};
    GetBase: (self: ConfigVariable, key: string) -> any;
    GetFinal: (self: ConfigVariable, key: string) -> any;

    Calculate: (self: ConfigVariable, baseValues: {any}?, modifiers: {any}?, finalValues: {any}?) -> {any};

    GetModifier: (self: ConfigVariable, id: string) -> (number?, ConfigModifier?);
    AddModifier: (self: ConfigVariable, modifier: ConfigModifier, recalculate: boolean?) -> nil;
    RemoveModifier: (self: ConfigVariable, id: string, recalculate: boolean?) -> ConfigModifier?;

    Destroy: (self: ConfigVariable) -> nil;

    -- @signals
    OnCalculate: EventSignal<anydict>;

    -- @meta
    [string]: any; -- quick index FinalValues;
};

export type ConfigModifier = {
    Id: string;
    Name: string;
    Priority: number;
    Tags: anydict;
    Values: anydict; 

    Enabled: boolean;
    SetEnabled: (self: ConfigModifier, value: boolean) -> nil;
    OnEnabledChanged: EventSignal<boolean>;

    BaseValues: anydict;
    SetValues: anydict;
    SumValues: anydict;
    ProductValues: anydict;
    MaxValues: anydict;
    MinValues: anydict;

    -- @methods
    Update: (self: ConfigModifier) -> nil;
};

--MARK: EquipmentClass
export type EquipmentClass = {
    -- @properties
    Enabled: boolean;

    ItemId: string;
    Class: string;
    Package: anydict;

    Configurations: ConfigVariable;
    Properties: {[any]: any};

    BaseModifiers: {[string]: anydict};
    EquipmentModifier: ConfigModifier;

    -- @methods
    SetEnabled: (self: EquipmentClass, value: boolean) -> nil;
    Update: (self: EquipmentClass, storageItem: StorageItem?) -> nil;
    Destroy: (self: EquipmentClass) -> nil;
    
    AddBaseModifier: (self: EquipmentClass, modifierId: string, config: {
        BaseValues: anydict?;
        SetValues: anydict?;
        SumValues: anydict?;
        ProductValues: anydict?;
        MaxValues: anydict?;
        MinValues: anydict?;
    }) -> nil;
    
    UpdateModifiers: (self: EquipmentClass, modifiers: {[string]: ConfigModifier}) -> nil;
    ProcessModifiers: (self: EquipmentClass, processType: string, ...any) -> nil;
    GetClassAsModifier: (self: EquipmentClass, siid: string, configModifier: ConfigModifier?) -> ConfigModifier;
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
    bind: (cmdDict: {[string]: anydict}) -> nil;
};

--MARK: ItemModifier
export type ItemModsLibrary = {
    calculateLayer: (itemModifier: ItemModifier, upgradeKey: string) -> {[any]: any};
};

type ModifierHookNames = "OnBulletHit" | "OnNewDamage" | "OnWeaponRender";
export type ItemModifier = {
    ClassName: string;
    Library: ItemModsLibrary;

    Tags: anydict;
    Binds: anydict;

    Ready: (self: ItemModifierInstance) -> nil;
    Update: (self: ItemModifierInstance) -> nil;
    SetTickCycle: (self: ItemModifierInstance, value: boolean) -> nil;
   
    Sync: (self: ItemModifier, syncKeys: {string}) -> nil;
    
    OnTick: ((self: ItemModifierInstance, tickData: TickData) -> nil)?;
};

export type ItemModifierInstance = {
    Script: ModuleScript;
    Name: string;

    Player: Player?;
    ModLibrary: ({any}?);
    EquipmentClass: EquipmentClass?;
    EquipmentStorageItem: StorageItem?;
    ItemModStorageItem: StorageItem?;

} & ItemModifier & ConfigModifier;

--MARK: Destructible
export type Destructible = {
    -- @properties
    ClassName: string;
    Script: Script;
    Model: Model;

    Class: string;

    HealthComp: HealthComp;
    StatusComp: StatusComp?;
    
    -- @signals
    OnDestroy: EventSignal<any>;
};

--MARK: Mission 
export type Mission = {
    -- @properties
    ClassName: string;
    Player: Player;
    Library: anydict;

    Id: number;
    Type: number;
    Expiration: number;
    ProgressionPoint: number;
    
    -- @signals
    OnChanged: EventSignal<any>;
}

--MARK: -- Data Models
-- Data packs that stores values to be passed into functions.
--
--
--
--
--
--MARK: ComponentOwner
export type ComponentOwner = {
    ClassName: string;
    Script: Script?;

    HealthComp: HealthComp?;
    StatusComp: StatusComp?;
    
    Character: Model?;
    Model: Model?;
} & anydict;

--MARK: DamageData
type damageData = {
    Damage: number;
    DamageType: DAMAGE_TYPE<string>;

    DamageBy: CharacterClass?; 
    DamageTo: CharacterClass?;
    TargetPart: BasePart?;
    TargetModel: Model?;
    DamageCate: string?;
    ToolHandler: ToolHandlerInstance?;
    StorageItem: StorageItem?;

    DamageForce: Vector3?;
    DamagePosition: Vector3?;
};
export type DamageData = damageData & {
    -- @static
    new: (damageData: damageData) -> DamageData;

    -- @properties

    -- @methods
    Clone: (self: DamageData) -> DamageData;
};

export type TickData = {
    Delta: number;
    ms100: boolean;
    ms500: boolean;
    ms1000: boolean;
    s5: boolean;
    s10: boolean;
};

export type StatusCompApplyParam = {
    Expires: number?;
    Duration: number?;
    ExpiresOnDeath: boolean?;

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

export type ArcPoint = {
    -- @properties
    Hit: BasePart?;
    Origin: Vector3;
    Velocity: Vector3;
    Direction: Vector3;
    Point: Vector3;
    Displacement: number;
    Normal: Vector3?;
    Material: Enum.Material?;
    TotalDelta: number;
    
    -- @methods
    Recast: (self: ArcPoint) -> nil;
}

export type EventInvokeParam = {
    SendBy: Player?;
    ReplicateTo: {Player}?
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
    base: HealthComp;
    getByModel: (model: Model) -> HealthComp?;

    -- @properties
    CompOwner: ComponentOwner;
    IsDead: boolean;
    
    CurHealth: number;
    MaxHealth: number;
    KillHealth: number;
    
    CurArmor: number;
    MaxArmor: number;

    FirstDamageTaken: number?;
    LastDamagedBy: CharacterClass?;
    
    LastDamageTaken: number;
    LastArmorDamageTaken: number;
    
    CanBeHurtBy: ({ -- Checks based on CharacterClass properties
        Humanoid: ({string})?;
        ClassName: ({string})?;
        Name: ({string})?;
        Teams: ({string})?; -- Checks for existing TeamComp;
    })?;
    
    -- @methods
    GetModel: (self: HealthComp) -> Model?;
    CanTakeDamageFrom: (self: HealthComp, characterClass: CharacterClass) -> boolean;    
    TakeDamage: (self: HealthComp, DamageData: DamageData) -> nil;
    
    SetHealth: (self: HealthComp, value: number) -> nil;
    SetMaxHealth: (self: HealthComp, value: number) -> nil;

    SetArmor: (self: HealthComp, value: number) -> nil;
    SetMaxArmor: (self: HealthComp, value: number) -> nil;
   
    -- @signals
    OnHealthChanged: EventSignal<DamageData?>;
    OnArmorChanged: EventSignal<any>;
    OnIsDeadChanged: EventSignal<>;
}

--MARK: StatusComp
export type StatusComp = { 
    -- @properties
    Id: string;
    CompOwner: ComponentOwner;
    List: {[string]: StatusClassInstance};
    Remote: RemoteEvent;
    ProcessNextStep: boolean;
    UseScheduler: boolean;

    -- @methods
    Apply: (self: StatusComp, uid: string, value: StatusCompApplyParam?) -> StatusClassInstance;
    GetOrDefault: (self: StatusComp, uid: string, value: anydict?) -> StatusClassInstance;

    Process: (self: StatusComp, loopFunc: ((uid: string, statusClass: StatusClassInstance, processData: anydict)->nil)?, fireOnProcess: boolean?) -> nil;
    
    Sync: (self: StatusComp, uid: string, players: any) -> nil;

    -- @signals
    OnProcess: EventSignal<any>;
};

--MARK: WieldComp
export type WieldComp = {
    -- @properties
    CompOwner: ComponentOwner;
    
    Controls: {
        Mouse1Down: boolean;
        [string]: boolean;
    };
    TargetableHumanoidType: {[string]: boolean};

    ToolHandler: ToolHandlerInstance?;
    Siid: string?;
    ItemId: string?;
    EquipmentClass: EquipmentClass?;

    EquipmentClassList: {EquipmentClass};
    ToolHandlerList: {ToolHandlerInstance};
    ItemModifierList: {ItemModifierInstance};
    
    -- @methods
    GetEquipmentClass: (self: WieldComp, siid: string, itemId: string?, storageItem: StorageItem?) -> EquipmentClass;
    GetToolHandler: (self: WieldComp, siid: string, itemId: string, storageItem: StorageItem?, toolModels: ({Model}?)) -> ToolHandlerInstance;
    GetOrDefaultItemModifier: (self: WieldComp, siid: string, defaultFunc: (()->ItemModifierInstance)?) -> ItemModifierInstance?;
    
    Equip: (self: WieldComp, args: {ItemId: string; MockEquip: boolean?;}) -> nil;
    Unequip: (self: WieldComp) -> nil;
    Destroy: (self: WieldComp) -> nil;

    InvokeToolAction: (self: WieldComp, actionName: string, ...any) -> ...any;
}