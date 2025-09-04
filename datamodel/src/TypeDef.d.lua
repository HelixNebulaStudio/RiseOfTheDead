export type anydict = {[any]: any};
export type anyfunc = ((...any)->...any);

-- constant uniontypes
export type GAME_EVENT_KEY<U> = U
    | "Crates_BindSpawn"
    | "Generic_BindClockTick"
    | "Generic_BindItemPickup"
    | "Generic_BindTrigger"
    | "Interactables_BindButtonInteract"
    | "Interactables_BindDoorInteract"
    | "Npcs_BindEnemiesAttract"
    | "Npcs_BindDamaged"
    | "Players_BindSpawn"
    | "Players_BindDamaged"
    | "Players_BindHeal"
    | "Profile_BindPlayPoints"
    | "Players_BindWieldEvent"
    | "Tools_BindHealTool"
    | "Tools_BindFoodTool"
    | "WeatherService_BindWeatherSet"
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
    IsNan: (number | Vector3 | Vector2) -> boolean;
    Notify: (player: Player | {Player}, message: string, notifyTypes: NOTIFY_TYPE, notifyId: string?, notifySettings: anydict?) -> nil;

    -- @game globals
    WorldCore: anydict;
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
    ConnectOnPlayerAdded: (EngineCore, src: Script | LocalScript | ModuleScript, func: (player: Player)->...any, order: number?) -> nil;
    ConnectOnPlayerRemoved: (EngineCore, src: Script | LocalScript | ModuleScript, func: (player: Player)->...any) -> nil;
    connectPlayers: () -> nil;
    loadWorldCore: (worldName: string) -> nil;
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

    Require: (Debugger, ModuleScript, boolean?) -> any;
    Ray: (Debugger, Ray, BasePart?, Vector3?, Vector3?) -> BasePart;
    Point: (Debugger, (CFrame | Vector3), Instance) -> Attachment;
    PointPart: (Debugger, (CFrame | Vector3)) -> BasePart;

    Stringify: (Debugger, ...any) -> string;
    StudioLog: (Debugger, ...any) -> nil;
    StudioWarn: (Debugger, ...any)  -> nil;
    Warn: (Debugger, ...any) -> nil;

    Debounce: (Debugger, string, number) -> boolean;
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
    Fire: (EventSignal<T...>, ...any) -> nil;
    Wait: (EventSignal<T...>, timeOut: number?) -> ...any;
    Connect: (EventSignal<T...>, (T...) -> ...any) -> (() -> nil);
    Disconnect: (EventSignal<T...>, func: any) -> nil;
    Once: (EventSignal<T...>, func: (T...)-> ...any) -> (() -> nil);
    Destroy: (EventSignal<T...>) -> nil;
    DisconnectAll: (EventSignal<T...>) -> nil;
};

--MARK: EventPacket
export type EventPacket = {
    Key: GAME_EVENT_KEY<string>;
    Source: number;

    Cancelled: boolean;
    Completed: boolean;

    Player: Player?;
    Players: {[number]: Player}?;

    Returns: anydict;

    --@methods
    SetCancelled: (EventPacket, boolean) -> nil; 
}

--MARK: EventHandler
export type EventHandler = {
    Key: string;
    
    ReplicateToClients: boolean;
    RelayToServer: boolean;

    -- @methods
    SetPermissions: (EventHandler, flagTag: string, value: boolean) -> nil;
    HasPermissions: (EventHandler, flagTag: string, player: Player?) -> boolean;
    SetPlayerPermissions: (EventHandler, player: Player, flagTag: string, value: boolean) -> nil;
};

--MARK: EventService
export type EventService = {
    -- @properties
    EventSource: {
        Client: number;
        Server: number;
    };

    -- @methods
    ClientInvoke: (
        EventService, 
        key: GAME_EVENT_KEY<string>, 
        invokeParam: EventInvokeParam, 
        ...any?
    ) -> EventPacket;
    ServerInvoke: (
        EventService, 
        key: GAME_EVENT_KEY<string>, 
        invokeParam: EventInvokeParam, 
        ...any?
    ) -> EventPacket;
    OnInvoked: (
        EventService, 
        key: GAME_EVENT_KEY<string>, 
        (event: EventPacket, ...any) -> nil, 
        priority: number?
    ) -> (()->nil);
    GetOrNewHandler: (
        EventService,
        key: GAME_EVENT_KEY<string>,
        newIfNil: boolean?
    ) -> EventHandler;
};


--MARK: Profiles
export type Profiles = {
    -- @static
    new: (player: Player) -> Profile;

    -- @methods
    Get: (Profiles, player: Player) -> Profile;
    Find: (Profiles, playerName: string) -> Profile;
    WaitForProfile: (Profiles, player: Player, duration: number?) -> Profile;
    IsPremium: (Profiles, player: Player) -> boolean;
};

export type Profile = {
    -- @properties
    Player: Player;
    UserId: number;
    Saves: anydict;
    LastOnline: number;

    Garbage: GarbageHandler;

    GameSave: GameSave;
    ActiveGameSave: GameSave;
    ActiveInventory: Storage;

    Premium: boolean;
    GamePass: anydict;

    Cache: anydict;
    
    -- @methods
    Save: (Profile, overrideData: any?, force: boolean?) -> nil;
    GetActiveSave: (Profile) -> GameSave;
    Sync: (Profile, hierarchyKey: string?, paramPacket: anydict?) -> nil;

    GetCacheStorages: (Profile) -> {[string]: Storage};
    AddPlayPoints: (Profile, points: number?, reason: string?) -> nil;

    InitMessaging: (Profile) -> nil;

    -- @binds
    _new: (Profile, player: Player) -> nil;
    _key_load: (Profile, key: string, data: any, loadOverwrite: anydict?) -> boolean; -- handled if true;
    _reset_save: (Profile) -> nil;
    _sync: (Profile, hierarchyKey: string?, paramPacket: anydict?) -> nil;
    _save: (Profile, overrideData: any?, force: boolean?) -> nil;
    _sync_public: (Profile, publicData: anydict, caller: Player) -> nil;
} & Profiles;

--MARK: GameSave
export type GameSave = {
    -- @properties
    Player: Player;
    Profile: Profile;
    Missions: MissionsProfile;

    Inventory: Storage;
    Clothing: Storage;

    Storages: {[string]: Storage};

    AppearanceData: AppearanceData;
    Events: anydict;

    -- @methods
    GetActiveSave: (GameSave) -> GameSave;
    Sync: (GameSave, hierarchyKey: string?) -> nil;
    GetStat: (GameSave, k: string) -> any;
    AddStat: (GameSave, k: string, v: number, force: boolean?) -> number;

    -- @binds
    _new: (gameSave: GameSave, profile: Profile) -> nil;
    _load_storage: (gameSave: GameSave, storageId: string, rawStorage: anydict) -> nil;
    _loaded: (gameSave: GameSave) -> nil;
};

export type MissionsProfile = {
    -- @methods
    Get: (MissionsProfile, missionId: number) -> Mission?;
};

--MARK: Storage
export type Storages = {
    -- @static
    get: (sid: string, player: Player?) -> Storage?;
    openStorage: (storageId: string, params: {
        StoragePresetId: string;

	    StoragePresetLib: anydict?;
	    Player: Player?;
	    InteractConfig: Configuration?;
	    Siid: string?;
	    StoragePage: number?;
	    StorageName: string?;
    }) -> Storage;

    fulfillList: (Player, list: {
        {ItemId: string; Amount: number;}
    }) -> (boolean, {anydict});
    consumeList: ({
        {Item: StorageItem; Amount: number; Storage: Storage;}
    }) -> nil;

    listItemIdFromStorages: (itemId: string, player: Player, customStorages: {string}?) -> (
        {{Item: StorageItem, Storage: Storage}}, 
        number
    );

    -- @methods
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
    Player: Player;
    PresetId: string;
    IsPublic: boolean;

    Initialized: boolean;
    MaxPages: number;
    Page: number;
    Size: number;
    MaxSize: number;
    PremiumStorage: number;
    Expandable: boolean;
    Virtual: boolean;
    Settings: anydict;
    Values: anydict;
    Cache: anydict;

    Locked: boolean;
    ViewOnly: boolean;

    Container: {[string]: StorageItem};
    LinkedStorages: anydict;

    StorageBitString: string;
    UsersBitString: {[string]: string};

    Garbage: GarbageHandler;

    -- @methods
    Load: (Storage, rawdata: anydict) -> Storage;
    Find: (Storage, id: string) -> StorageItem;
    Insert: (Storage, storageItem: StorageItem) -> (string, anydict);
    InsertRequest: (Storage, storageItem: StorageItem, ruleset: {
        ForceIndex: number?;
        CancelIfCantFitAll: boolean?;
    }?) -> anydict;
    SpaceCheck: (Storage, items: {any}) -> boolean;
    Add: (Storage, itemId: string, data: {Quantity: number?; Data: anydict?}?, callback: anyfunc?) -> nil;
    Remove: (Storage, siid: string, amount: number?, callback: anyfunc?) -> nil;
    Delete: (Storage, siid: string, amount: number?, callback: anyfunc?) -> nil;
    Loop: (Storage, func: ((storageItem: StorageItem) -> boolean)?) -> number;
    ConnectCheck: (Storage, anyfunc) -> nil;
    Destroy: (Storage) -> nil;

    SetPermissions: (Storage, flagTag: string, value: boolean) -> nil;
    HasPermissions: (Storage, flagTag: string, name: string?) -> boolean;
    SetUserPermissions: (Storage, name: string, flagTag: string, value: boolean) -> nil;

    InitStorage: (Storage) -> nil;
    TransferContainer: (Storage, transferTo: Storage) -> nil;
    SetOwner: (Storage, Player) -> nil;
    Wipe: (Storage) -> nil;
    Shrink: (Storage) -> anydict;
    BindActionHandler: (Storage, actionKey: string, func: ((Storage, {
        Player: Player;
        StorageId: string;
        Id: string;
        Action: string;
        [string]: any;
    })->nil)) -> nil;

    GetIndexDictionary: (Storage) -> {[number]: StorageItem};
    FindByIndex: (Storage, index: number) -> StorageItem;

    Sync: (Storage, player: Player) -> nil;
    SyncValues: (Storage, Player?) -> nil;

    -- @signals
    OnChanged: EventSignal<>;
};

--MARK: StorageItem
export type StorageItem = {
    -- @properties
    ID: string;
    Index: number;
    ItemId: string;
    Player: Player;
    Storage: Storage;
    Library: {[string]: any};
    Values: {[string]: any};
    Quantity: number;
    IsFake: boolean;
    
    -- @methods
    Sync: (StorageItem, keys: {string}?) -> nil;
    GetValues: (StorageItem, key: string) -> any;
    SetValues: (StorageItem, key: string, value: any?, syncFunc: any?) -> StorageItem;
    Clone: (StorageItem) -> StorageItem;
}


--MARK: AppearanceData
export type AppearanceData = {
    -- @properties
    UpdateReady: boolean;

    -- @methods
    Update: (AppearanceData, Storage) -> nil;
    GetAccessories: (AppearanceData, siid: string) -> {Accessory};
};


--MARK: PlayerClass
export type PlayerClasses = {
    -- @static
    get: (Player) -> PlayerClass;
    getByName: (name: string) ->  PlayerClass;
    getAvatar: (userId: number) -> string;
    getPlayersInRange: (origin: Vector3, radius: number) -> {Player};
    
    -- @signals
    OnPlayerDied: EventSignal<PlayerClass>;
};

export type PlayerClass = CharacterClass & {
    -- @properties
    Name: string;

    IsSwimming: boolean;

    CharacterVars: anydict;
    Configurations: ConfigVariable;
    Properties: PropertiesVariable<{
        IsUnderWater: boolean;
    }>;

    LastDamageDealt: number;
    LastHealed: number;

    LowestFps: number;
    AverageFps: number;

    IsTeleporting: boolean;
    TeleportPlaceId: number;

    Invisible: boolean;
    CurrentState: Enum.HumanoidStateType;

    CharacterGarbage: GarbageHandler;

    Cache: anydict;

    -- @methods
    Spawn: (PlayerClass) -> nil;
    Despawn: (PlayerClass) -> nil;
    Kill: (PlayerClass, reason: string?) -> nil;
    GetInstance: (PlayerClass) -> Player;
    
    GetCFrame: (PlayerClass) -> CFrame;
    SetCFrame: (PlayerClass, cframe: CFrame) -> CFrame;

    SyncProperty: (PlayerClass, key: string, players: any) -> nil;

    RefreshHealRate: (PlayerClass) -> nil;

    OnDeathServer: (PlayerClass)->nil;
    OnCharacterAdded: (character: Model)->nil;
    OnPlayerTeleport: ()->nil;
    
    -- @signals
    OnIsDeadChanged: EventSignal<any>;
    OnDamageTaken: EventSignal<any>;
    OnCharacterSpawn: EventSignal<any>;

    -- @binds
    _new: (Class, PlayerClass) -> nil;
    _character_added: (Class, PlayerClass, character: Model) -> nil;
    _character_removing: (Class, PlayerClass, character: Model) -> nil;
    _status_tick_update: (Class, PlayerClass, TickData) -> nil;
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
    DistanceFromCharacter: (CharacterClass, pos: Vector3) -> number;
    GetHealthComp: (CharacterClass, bodyPart: BasePart) -> HealthComp?;
    Kill: (CharacterClass) -> nil;

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
    Cleansable: boolean;
};

export type StatusClass = {
    ClassName: string;

    Instance: (StatusClass) -> StatusClassInstance;
    Func: (StatusClassInstance, ...any) -> nil;

    BindApply: (StatusClassInstance) -> nil;
    BindUpdate: (StatusClassInstance) -> nil;
    BindExpire: (StatusClassInstance) -> nil;
    BindTickUpdate: (StatusClassInstance, TickData) -> nil;
    BindRelay: (StatusClassInstance, ...any) -> nil;
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
    Text: string?;

    
    -- @methods
    Sync: (StatusClassInstance, players: any)->nil; --Server to Client
    Relay: (StatusClassInstance, ...any)->nil; --Client to Server
    Shrink: (StatusClassInstance) -> anydict;
} & StatusClass;

--MARK: AnimationController
export type AnimationController = {
    Update: (AnimationController) -> nil;
};

--MARK: NpcClasses
export type NpcClasses = {
    -- @static
    ActiveNpcClasses: {NpcClass};
    NpcBaseConstructors: anydict;

    getByModel: (Model) -> NpcClass?;
    getById: (number) -> NpcClass?;
    getPlayerNpc: (player: Player, npcName: string) -> NpcClass?;
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
        Player: Player?;

        AddComponents: {string}?;
        AddBehaviorTrees: {string}?;
        
        CustomNpcPrefab: Instance?;
        ReplicateOut: boolean?;
            
        BindSetup: ((npcClass: NpcClass) -> nil)?;
    }) -> NpcClass;
    
    -- @signals
    OnNpcSpawn: EventSignal<NpcClass>;
};


export type NpcMoveComponent = {
    -- @properties
    SetDefaultWalkSpeed: number;

    -- @methods
    Init: anyfunc;
    HeadTrack: (NpcMoveComponent, part: BasePart, expireTime: number) -> nil;
    MoveTo: (NpcMoveComponent, position: Vector3) -> nil;
    Face: (NpcMoveComponent, target: Vector3 | BasePart | "Player", faceSpeed: number?, duration: number?) -> nil;
    LookAt: (NpcMoveComponent, point: Vector3 | BasePart) -> nil;
    Follow: (NpcMoveComponent, target: (Vector3 | BasePart)?, maxFollowDist: number?, minFollowDist: number?, followGapOffset: number?) -> nil;
    SetMoveSpeed: (NpcMoveComponent, action: string?, id: string?, speed: number?, priority: number?, expire: number?) -> nil;
    IsAtPosition: (NpcMoveComponent, position: Vector3) -> boolean;
    Stop: (NpcMoveComponent, waitForStop: number?) -> nil;
    Pause: (NpcMoveComponent, pauseTime: number?) -> nil;
    Resume: (NpcMoveComponent) -> nil;
    Recompute: (NpcMoveComponent) -> nil;
    Fly: (NpcMoveComponent, trajPoints: ({{Velocity: Vector3;Direction: Vector3;}})?, delta: number, onStepFunc: anyfunc?) -> nil;

    -- @signals
    OnMoveToEnded: EventSignal<any>;
}

--MARK: NpcClass
export type NpcClass = CharacterClass & {
    -- @properties
    Id: number;
    SpawnPoint: CFrame;
    IsReady: boolean;

    Player: Player?;
    NetworkOwners: {Player};

    Actor: Actor;
    ActorEvent: BindableEvent;

    BehaviorTree: anydict;
    PathAgent: anydict;

    NpcPackage: anydict;
    NpcComponentsList: {string};
    
    Storages: {[string]: Storage};
    Binds: anydict;

    AnimationController: AnimationController;
    Interactable: ModuleScript?;
    
    -- @methods
    Setup: (NpcClass, baseNpcModel: Model, npcModel: Model) -> nil;
    Destroy: (NpcClass) -> nil;
    TeleportHide: (NpcClass) -> nil;

    AddComponent: (NpcClass, component: string | ModuleScript) -> nil;
    GetComponent: (NpcClass, componentName: string) -> any;
    ListComponents: (NpcClass) -> {any};
    
    SetCFrame: (NpcClass, cframe: CFrame?, angle: CFrame?) -> nil;
    IsInVision: (NpcClass, object: BasePart, fov: number?) -> boolean;
    DistanceFrom: (NpcClass, pos: Vector3) -> number;
    ToggleInteractable: (NpcClass, v: boolean) -> nil;
    UseInteractable: (NpcClass, interactableId: string, ...any) -> ...any;
    IsRagdolling: (NpcClass) -> boolean;
    GetMapLocation: (NpcClass) -> string;
    Sit: (NpcClass, Seat) -> nil;

    -- @signals
    OnThink: EventSignal<any>;

    -- @components
    SetAnimation: (animName: string, animList: {Animation}) -> nil;
    GetAnimation: (animName: string) -> AnimationTrack?;
    PlayAnimation: (animName: string, ...any) -> AnimationTrack; 
    StopAnimation: (animName: string, ...any) -> nil;
    Move: NpcMoveComponent;
    Chat: (player: Player?, message: string) -> nil;


    -- @dev
    GetImmunity: (NpcClass, damageType: string?, damageCategory: string?) -> number; 
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
    new: (Configuration, Model?) -> (InteractableInstance, InteractableMeta);
    registerPackage: (name: string, package: anydict) -> nil;

    Instance: (name: string, config: Configuration) -> InteractableInstance;
}

export type InteractableMeta = {
    Name: string;
    Type: string;
    Label: string;
    TouchInteract: boolean; 
    IndicatorPresist: boolean;
    InteractableRange: number;
    InteractDuration: number;
    Remote: RemoteFunction;

    Package: anydict;
    TypePackage: anydict;
    Whitelist: {[string]: boolean};
    
	RootBitString: string;
	UserBitString: {[string]: string};

    LastDataChanged: number;
    LastPermChanged: number;
    LastProximityTrigger: number;

    -- @methods
    Trigger: (InteractableInstance) -> nil;

    InteractServer: (InteractableInstance, values: anydict) -> nil;

    SetPermissions: (InteractableInstance, flagTag: string, value: boolean) -> nil;
    HasPermissions: (InteractableInstance, flagTag: string, name: string?) -> boolean;
    SetUserPermissions: (InteractableInstance, name: string, flagTag: string, value: boolean) -> nil;
    ClearPermissions: (InteractableInstance) -> nil;
}

export type InteractableInstance = {
    -- @properties
    Id: string;

    Config: Configuration;
    Part: BasePart;
    Point: Vector3;

    Variant: string;

    CanInteract: boolean;
    Values: anydict;

    Prefab: Instance?;
    Label: string?;
    Animation: string?;

    -- @methods
    Sync: (InteractableInstance, players: {Player}?, data: anydict?) -> nil;
    SyncPerms: (InteractableInstance, player: Player) -> nil;
    Shrink: (InteractableInstance) -> anydict;
    IsDebounced: (InteractableInstance, name: string, duration: number?) -> boolean;

    BindInteract: (interactable: InteractableInstance, info: InteractInfo) -> nil;
    BindPrompt: (interactable: InteractableInstance, info: InteractInfo) -> nil;
    BindSync: (interactable: InteractableInstance, data: anydict) -> nil;
    
} & InteractableMeta;

export type InteractInfo = {
    ActionSource: {
        Client: string;
        Server: string;
    };
    Values: anydict;

    Action: string?;
    Player: Player?;

    -- @client
    ClientData: anydict?;
    ClientInterface: anydict?;
    CharacterVars: anydict?;

    -- @server
    NpcClass: NpcClass?;
};

--MARK: Scheduler
export type SchedulerJob = {
    Routine: any;
    T: number?;
    Arguments: anydict;
};

export type Scheduler = {
    -- @properties;
    Name: string;
    Rate: number;

    -- @methods
    ScheduleFunction: (Scheduler, f: anyfunc, fireTick: number) -> SchedulerJob;
    Wait: (Scheduler, f: anyfunc) -> any;
    Schedule: (routine: any, fireTick: number, ...any) -> SchedulerJob;
    Unschedule: (Scheduler, SchedulerJob) -> boolean;

    -- @signals
    OnStepped: EventSignal<TickData>;
};

--MARK: DropdownList
export type DropdownList = {
    SetZIndex: (DropdownList, number) -> nil;
    SetPosition: (DropdownList, Vector2) -> nil;
    OnOptionClick: (DropdownList, anyfunc) -> nil;
    Destroy: (DropdownList) -> nil;
};

--MARK: Interface
export type Interface = {
    -- @static;
    setPositionWithPadding: (guiObject: GuiObject, position: UDim2?, padding: Vector2?) -> nil;
    newTemplate: (name: string) -> any;
    newDropdownList: (options: {
        Text: string?; 
        LayoutOrder: number?; 
        Size: UDim2?; 
        TextColor3: Color3?; 
        BackgroundColor3: Color3?;
        OnNewButton: anyfunc?;
    }, newButtonTemplate: GuiObject?) -> DropdownList;

    -- @properties;
    ActiveLayerBoolString: string?;
    Script: Script;
    ScreenGui: ScreenGui;
    Garbage: GarbageHandler;
    Scheduler: Scheduler;

    Windows: {[string]: InterfaceWindow};
    Elements: {[string]: InterfaceElement};

    Properties: PropertiesVariable<{
        DisableInteractables: boolean;
        DisableHotKeys: boolean;
        DisableHotKeysHint: boolean;
        PrimaryInputDown: boolean;
        ShiftInputDown: boolean;
        AltInputDown: boolean;
        TopbarInset: Rect;
        IsCompactFullscreen: boolean;
    }>;

    Colors: {
        Branch: Color3;
        Green: Color3;
        Red: Color3;
        [string]: Color3;
    };

    GameBlindsFrame: Frame;
    QuickBarButtons: Frame;
    CutsceneNextButton: TextButton;
    MouseLockHint: Frame;
    AimPointer: ImageLabel;
    VersionLabel: TextLabel;
    ColorPicker: any;
    
    StorageInterfaces: {StorageInterface};
    StorageInterfaceIndex: number;

    -- @methods
    Destroy: (InterfaceWindow) -> nil;
    Init: (Interface) -> nil;
    RefreshInterfaces: (Interface) -> nil;

    GetWindow: (Interface, name: string) -> InterfaceWindow;
    NewWindow: (Interface, name: string, frame: GuiObject, properties: anydict?) -> InterfaceWindow;
    ToggleWindow: (Interface, name: string, visible: boolean?, ...any) -> InterfaceWindow;
    ListWindows: (Interface, conditionFunc: anyfunc) -> {InterfaceWindow};
    Freeze: (Interface, value: boolean) -> nil;
    
    BindConfigKey: (Interface, key: string, windows: {InterfaceWindow}?, frames: {Instance}?, conditions: ((...any) -> boolean)?) -> nil;
    BindEvent: (Interface, key: string, func: (...any)->nil) -> (()->nil);
    FireEvent: (Interface, key: string, ...any) -> nil;

    NewQuickButton: (Interface, name: string, hint: string, image: string) -> ImageButton;
    ConnectQuickButton: (Interface, obj: ImageButton, keyId: string?, onClickFunc: (()->nil)?) -> nil;

    HideAll: (Interface, blacklist: anydict?) -> nil;

    GetOrDefaultElement: (Interface, name: string, default: anydict?) -> InterfaceElement;

    ToggleGameBlinds: (Interface, openBlinds: boolean, duration: number) -> nil;
    PlayButtonClick: (Interface) -> nil;
    ConnectImageButton: (Interface, button: ImageButton) -> nil;

    -- @signals
    OnReady: EventSignal<>;
    OnInterfaceEvent: EventSignal<string>;
    OnWindowToggle: EventSignal<InterfaceWindow, boolean>;
};

--MARK: InterfaceInstance
export type InterfaceInstance = {
    -- @static
    Templates: {
        Checkbox: Frame;
        ScrollingFrame: ScrollingFrame;
        QuickButton: ImageButton;
        BasicButton: TextButton;
        ItemSlot: ImageLabel;
        [string]: GuiObject;
    };

    -- @properties
    Package: anydict;
} & Interface;

--MARK: InterfaceWindow
export type InterfaceWindow = {
    -- @properties
    Name: string;
    Frame: Frame;
    QuickButton: GuiObject;

    _visible: boolean;
    Visible: boolean;
    DisabledByConfig: boolean;

    ClosePoint: UDim2;
    OpenPoint: UDim2;

    Layers: {string};
    BoolStringWhenActive: {String: string; Priority: number;};

    Binds: anydict;
    Properties: PropertiesVariable<{}>;
    
    UseTween: boolean;
    ReleaseMouse: boolean;
    DisableInteractables: boolean;
    DisableOpeningWindows: boolean;
    DisableHotKeysHint: boolean;
    CloseWithInteract: boolean;
    IgnoreHideAll: boolean;
    UseMenuBlur: boolean;
    CompactFullscreen: boolean;

    -- @methods
    Init: (InterfaceWindow) -> nil;
    Toggle: (InterfaceWindow, visible: boolean?, ...any) -> nil;
    Open: (InterfaceWindow, ...any) -> nil;
    Close: (InterfaceWindow, ...any) -> nil;
    Update: (InterfaceWindow, ...any) -> nil;
    SetClosePosition: (InterfaceWindow, close: UDim2, open: UDim2?) -> nil;
    AddCloseButton: (InterfaceWindow, object: GuiObject) -> nil;
    Destroy: (InterfaceWindow) -> nil;

    -- @signals
    OnToggle: EventSignal<boolean>;
    OnUpdate: EventSignal<any>;
};

--MARK: InterfaceElement
export type InterfaceElement = PropertiesVariable<anydict> & {
    Layers: {string};
    Visible: boolean;
};

--MARK: ItemSlot
export type ItemSlot = {
    ID: string;
    Index: number;
    ItemId: string;
    Item: StorageItem;
    Button: ImageButton;
    QuantityLabel: TextLabel;
    Interface: StorageInterface;
    ItemButtonObject: anydict;
    Button: ImageButton;
    Slot: anydict;
};

--MARK: StorageInterface
export type StorageInterface = anydict & {

    --@methods
    GetItemSlotsOfSiid: (StorageInterface) -> {ItemSlot};
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
    Instance: (ToolHandler) -> ToolHandlerInstance;
    Destroy: (ToolHandler) -> ();
    PlayAudio: (ToolHandler, audioName: string, parent: Instance, playFunc: ((sound: Sound, audioInfo: anydict)->nil)?) -> Sound?;
    LoadWieldConfig: (ToolHandler) -> nil;

    Init: (toolHandler: ToolHandlerInstance) -> nil;
    Equip: (toolHandler: ToolHandlerInstance) -> nil;

    ClientEquip: (toolHandler: ToolHandlerInstance) -> nil;
    ClientUnequip: (toolHandler: ToolHandlerInstance) -> nil;

    ActionEvent: (toolHandler: ToolHandlerInstance, packet: {[any]: any}) -> nil;
    InputEvent: (toolHandler: ToolHandlerInstance, inputData: {[any]: any}) -> nil;

    ServerEquip: (toolHandler: ToolHandlerInstance) -> nil;
    ServerUnequip: (toolHandler: ToolHandlerInstance) -> nil;

    initInterface: () -> InterfaceWindow;
};

export type ToolHandlerInstance = {
    -- @properties
    CharacterClass: CharacterClass;
    WieldComp: WieldComp;

    StorageItem: StorageItem;
    ToolPackage: anydict;
    EquipmentClass: EquipmentClass;
    Garbage: GarbageHandler;

    MainToolModel: Model;
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
    PullTrigger: (toolHandler: ToolHandlerInstance) -> nil;
};
export type GunToolHandlerInstance = ToolHandlerInstance & GunToolHandler;

export type ToolAnimator = {
    Play: (
        ToolAnimator, 
        animName: string, 
        param: ({
            FadeTime: number?;
            PlaySpeed: number?;
            PlayLength: number?;
            PlayWeight: number?;
            [any]: any;
        })?
    ) -> AnimationTrack;
    Stop: (ToolAnimator,
        animKey: string,
        param: ({
            FadeTime: number?
        })?
    ) -> nil;
    StopAll: (ToolAnimator)->nil;

    GetPlaying: (ToolAnimator, animKey: string) -> AnimationTrack;
    GetKeysPlaying: (ToolAnimator, animKeys: {string}) -> {[string]: AnimationTrack};
    LoadAnimations: (ToolAnimator, animations: anydict, default: string, prefabs: {Model}) -> nil;
    ConnectMarkerSignal: (ToolAnimator, markerKey: string, func: ((animKey: string, track: AnimationTrack, value: any)->nil)) -> nil;
    
    GetState: (ToolAnimator) -> string;
    SetState: (ToolAnimator, state: string?) -> nil;
    HasState: (ToolAnimator, state: string) -> boolean;
    
    Init: (...any)->nil;
    TrackEvent: EventSignal<string, string, string>;
};

--MARK: PropertiesVariable
export type PropertiesVariable<T> = T & {
    IsDestroyed: boolean;
    Values: T;

    -- @signals
    OnDestroy: EventSignal<>;
    OnChanged: EventSignal<any, any, any>;

    -- @methods
    Loop: (PropertiesVariable<T>, func: ((any, any)->boolean)) -> nil;
    Destroy: (PropertiesVariable<T>) -> nil;

    SetMetatable: (PropertiesVariable<T>, mt: anydict) -> nil;
    GetMetatable: (PropertiesVariable<T>) -> any;

    [any]: any;
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
    GetKeyPairs: (ConfigVariable) -> {[any]: any};
    GetBase: (ConfigVariable, key: string) -> any;
    GetFinal: (ConfigVariable, key: string) -> any;

    Calculate: (ConfigVariable, baseValues: {any}?, modifiers: {any}?, finalValues: {any}?) -> {any};

    GetModifier: (ConfigVariable, id: string) -> (number?, ConfigModifier?);
    AddModifier: (ConfigVariable, modifier: ConfigModifier, recalculate: boolean?) -> nil;
    RemoveModifier: (ConfigVariable, id: string, recalculate: boolean?) -> ConfigModifier?;

    Destroy: (ConfigVariable) -> nil;

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
    SetEnabled: (ConfigModifier, value: boolean) -> nil;
    OnEnabledChanged: EventSignal<boolean>;

    BaseValues: anydict;
    SetValues: anydict;
    SumValues: anydict;
    ProductValues: anydict;
    MaxValues: anydict;
    MinValues: anydict;

    -- @methods
    Update: (ConfigModifier) -> nil;
};

--MARK: EquipmentClass
export type EquipmentClass = {
    -- @properties
    Enabled: boolean;

    ItemId: string;
    Class: string;
    Package: anydict;

    Configurations: ConfigVariable;
    Properties: PropertiesVariable<{}>;

    BaseModifiers: {[string]: anydict};
    EquipmentModifier: ConfigModifier;

    ClassSelf: any;

    -- @methods
    SetEnabled: (EquipmentClass, value: boolean) -> nil;
    Update: (EquipmentClass, storageItem: StorageItem?) -> nil;
    Destroy: (EquipmentClass) -> nil;
    
    AddBaseModifier: (EquipmentClass, modifierId: string, config: {
        BaseValues: anydict?;
        SetValues: anydict?;
        SumValues: anydict?;
        ProductValues: anydict?;
        MaxValues: anydict?;
        MinValues: anydict?;
    }) -> nil;
    
    UpdateModifiers: (EquipmentClass, modifiers: {[string]: ConfigModifier}) -> nil;
    ProcessModifiers: (EquipmentClass, processType: string, ...any) -> nil;
    GetClassAsModifier: (EquipmentClass, siid: string, configModifier: ConfigModifier?) -> ConfigModifier;
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

    HookChatCommand: (CommandsLibrary, cmd: string, cmdPacket: {
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

    Ready: (ItemModifierInstance) -> nil;
    Update: (ItemModifierInstance) -> nil;
    EnableTickUpdate: (ItemModifierInstance, value: boolean) -> nil;
   
    Sync: (ItemModifier, syncKeys: {string}) -> nil;
    
    FireBind: (ItemModifierInstance, bindName: string, ...any) -> nil;
    BindTickUpdate: ((ItemModifierInstance, tickData: TickData) -> nil)?;
};

export type ItemModifierInstance = {
    Script: ModuleScript;
    Name: string;

    WieldComp: WieldComp?;
    Player: Player?;
    ModLibrary: ({any}?);
    EquipmentClass: EquipmentClass?;
    EquipmentStorageItem: StorageItem?;
    ItemModStorageItem: StorageItem?;

} & ItemModifier & ConfigModifier;

--MARK: Destructible
export type Destructible = {
    InstanceList: {[Configuration]: DestructibleInstance};
    Db: {[string]: anydict};

    getOrNew: (config: Configuration) -> DestructibleInstance;
    Instance: (config: Configuration) -> DestructibleInstance;
};

export type DestructibleInstance = {
    -- @properties
    ClassName: string;
    Config: Configuration;
    Name: string;
    Model: Model;
    Package: anydict;

    Enabled: boolean;
    SetEnabled: (DestructibleInstance, value: boolean) -> nil;

    HealthComp: HealthComp;
    StatusComp: StatusComp;

    NetworkOwners: {Player};
    DebrisName: string;
    
    -- @signals
    OnDestroy: EventSignal<any>;
    OnEnabledChanged: EventSignal<boolean>;
}

--MARK: ArcTracer
export type ArcTracer = {
    -- @properties
    RayWhitelist: {Instance};
    RayRadius: number;
    Delta: number;
    Acceleration: Vector3;
    SpeedMultiplier: number;

    IgnoreWater: boolean;
    IgnoreEntities: boolean;
    AddTagsToArcTracer: {string};
    AirSpin: number;
    MaxBounce: number;
    DebugArc: boolean;

    --@methods
    GetVelocityByTime: (ArcTracer, origin: Vector3, target: Vector3, travelTime: number) -> Vector3;
    Destroy: (ArcTracer) -> nil;
    GeneratePath: (ArcTracer, origin: Vector3, velocity: Vector3, func: (ArcPoint)->boolean) -> {ArcPoint};

    BindStepped: (ArcTracer, ArcPoint, ...any) -> nil;
};

--MARK: ProjectileInstance
export type ProjectileInstance = {
    Id: string;
    Index: number;
    Part: MeshPart;
    OriginCFrame: CFrame;
    IsDestroyed: boolean;

    CharacterClass: CharacterClass?;
    StorageItem: StorageItem?;
    ToolHandler: ToolHandlerInstance?;

    Configurations: anydict;
    Properties: PropertiesVariable<anydict>;

    ArcTracer: ArcTracer;
    ArcTracerConfig: {
		Velocity: number;
		Bounce: number;
		LifeTime: number;
		MaxBounce: number;
		Delta: number;
        Acceleration: Vector3;
    };

    --@methods
    Destroy: (ProjectileInstance) -> nil;

    BindInstance: (ProjectileInstance) -> nil;
    BindFire: (ProjectileInstance) -> nil;
    BindDestroy: (ProjectileInstance) -> nil;
    BindArcStepped: (ProjectileInstance, ArcPoint) -> nil;
    BindArcContact: (ProjectileInstance, ArcPoint, ArcTracer) -> nil;
    BindArcComplete: (ProjectileInstance) -> nil;
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

--MARK: DoorInstance
export type DoorInstance = {
    -- @properties
    Config: Configuration;
    Model: Model;

    Open: boolean;
    DoorType: "Normal" | "Sliding";

    --@methods
    Toggle: (DoorInstance, open: boolean?, openerCFrame: CFrame?, player: Player?) -> nil;  
};

--MARK: TeamsManager
export type TeamsManager = {
    -- @properties
    Teams: {[string]: TeamClass};
    Teammates: {[string]: TeamMate};

    -- @methods
    getTeam: (guid: string) -> TeamClass?;
    getTeamByName: (name: string) -> TeamClass?;
    getTeamByPlayer: (player: Player, teamType: string) -> TeamClass?;
};

--MARK: TeamMate
export type TeamMate = {
    -- @properties
    Teams: {[string]: TeamClass};
};

--MARK: TeamClass
export type TeamClass = {
    -- @properties
    Guid: string;
    Name: string;
    Type: string;

    MembersCount: number;
    Members: {[string]: {
        Index: number;
        Name: string;
        UserId: number;
        InServer: boolean;
        Values: anydict;
    }};

    Values: anydict;

    Private: boolean;
    DestroyOnZeroMembers: boolean;

    --@methods
    SetMember: (TeamClass, name: string, isSet: boolean, proxyTeammate: anydict?) -> nil;
    ClientLoad: (TeamClass, data: anydict) -> nil;
    GetTeamAsync: (TeamClass) -> nil;
    Sync: (TeamClass) -> nil;
};

export type RadialImage = {
    Config: anydict;
    ImageLabel: ImageLabel;

    GetFromAlpha: (RadialImage, alpha: number) -> (number, number, number);
    UpdateLabel: (RadialImage, alpha: number, label: ImageLabel?) -> nil;
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
    TargetPart: BasePart;

    DamageType: DAMAGE_TYPE<string>?;
    DamageBy: CharacterClass?; 
    DamageTo: CharacterClass?;
    TargetModel: Model?;
    DamageCate: string?;
    ToolHandler: ToolHandlerInstance?;
    StorageItem: StorageItem?;

    DamageForce: Vector3?;
    DamagePosition: Vector3?;

    [any]: any;
};
export type DamageData = damageData & {
    -- @static
    new: (damageData: damageData) -> DamageData;

    -- @properties

    -- @methods
    Clone: (DamageData) -> DamageData;
};

--MARK: TickData
export type TickData = {
    Delta: number;
    ms100: boolean;
    ms500: boolean;
    ms1000: boolean;
    s5: boolean;
    s10: boolean;
};

--MARK: StatusCompApplyParam
export type StatusCompApplyParam = {
    Expires: number?;
    Duration: number?;
    ExpiresOnDeath: boolean?;

    Values: ({
        [any]: any;

        ImmunityReduction: number?;
    })?;
}

--MARK: OnBulletHitPacket
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

--MARK: ArcPoint
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
    LastPoint: boolean;
    ReflectToPoint: Vector3;
    Client: boolean;
    
    -- @methods
    Recast: (ArcPoint) -> nil;
}

--MARK: EventInvokeParam
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
    Id: string;
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
    
    CanBeHurtByBoolString: string?;
    
    -- @methods
    Reset: (HealthComp) -> nil;
    GetModel: (HealthComp) -> Model?;
    CanTakeDamageFrom: (HealthComp, characterClass: CharacterClass?) -> boolean;    
    TakeDamage: (HealthComp, DamageData: DamageData) -> nil;
    
    SetIsDead: (HealthComp, boolean, reason: anydict?) -> nil;
    SetHealth: (HealthComp, value: number, reason: anydict?) -> nil;
    SetMaxHealth: (HealthComp, value: number, reason: anydict?) -> nil;

    SetArmor: (HealthComp, value: number, reason: anydict?) -> nil;
    SetMaxArmor: (HealthComp, value: number, reason: anydict?) -> nil;
   
    SetCanBeHurtBy: (HealthComp, boolString: string?) -> nil;
    CheckCanBeHurtBy: ((HealthComp, {string})->boolean)?;

    BindCannotTakeDamage: (HealthComp, attackerCharacter: CharacterClass, shotInfo: {Part: BasePart; Index: number;}) -> nil;

    -- @signals
    OnHealthChanged: EventSignal<number, number, anydict?>;
    OnArmorChanged: EventSignal<number, number, anydict?>;
    OnIsDeadChanged: EventSignal<boolean, boolean, anydict?>;
}

--MARK: StatusComp
export type StatusComp = {
    -- @static
    getPackage: (statusId: string) -> anydict;

    -- @properties
    Id: string;
    CompOwner: ComponentOwner;
    List: {[string]: StatusClassInstance};
    Remote: RemoteEvent;
    ProcessNextStep: boolean;
    UseScheduler: boolean;

    -- @methods
    Apply: (StatusComp, uid: string, value: StatusCompApplyParam?) -> StatusClassInstance;
    GetOrDefault: (StatusComp, uid: string, value: anydict?) -> StatusClassInstance;

    Process: (StatusComp, loopFunc: ((uid: string, statusClass: StatusClassInstance, processData: anydict)->nil)?, fireOnProcess: boolean?) -> nil;
    
    Sync: (StatusComp, uid: string, players: any) -> nil;

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
    TargetableTags: {[string]: boolean};

    ToolHandler: ToolHandlerInstance?;
    Siid: string?;
    ItemId: string?;
    EquipmentClass: EquipmentClass?;

    EquipmentClassList: {EquipmentClass};
    ToolHandlerList: {ToolHandlerInstance};
    ItemModifierList: {ItemModifierInstance};
    
    -- @methods
    GetEquipmentClass: (WieldComp, siid: string, itemId: string?, storageItem: StorageItem?) -> EquipmentClass;
    GetToolHandler: (WieldComp, siid: string, itemId: string, storageItem: StorageItem?, toolModels: ({Model}?)) -> ToolHandlerInstance;
    GetOrDefaultItemModifier: (WieldComp, siid: string, defaultFunc: (()->ItemModifierInstance)?) -> ItemModifierInstance?;
    RefreshCharacterModifiers: (WieldComp) -> nil;

    SetCustomization: (WieldComp, mode: string, packet: anydict) -> nil;

    Equip: (WieldComp, args: {ItemId: string; MockEquip: boolean?;}) -> nil;
    Unequip: (WieldComp) -> nil;
    Destroy: (WieldComp) -> nil;

    InvokeToolAction: (WieldComp, actionName: string, ...any) -> ...any;
}