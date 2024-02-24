-- Web Code Execution --

-- @author: @binarychunk / zirt (morphine4life on discord)
-- @description: Execute lua scripts from your browser with several different methods for the execution. Uses the long-polling HTTP Method.

-- tip: use fione for faster execution (RERUBI SUCKS SORRY RERUMU)

--[[
    * credits:
        -> interpreters (fione,rerubi): https://github.com/Rerumu
        -> compilers (yueliang): https://yueliang.luaforge.net/
        -> coding: @binarychunk / zirt
]]
--------------------------


script:WaitForChild('ConnectionGui', 1); -- Connection GUI (w.i.p) --

script:WaitForChild('CleanEnv', 1); -- Module that returns an so-called empty environment. (security purposes) --
script:WaitForChild('Init', 1); -- Init Module. (For custom functions) --
script:WaitForChild('Modules', 1); -- Yield forever if missing (learn your lesson)
script:FindFirstChild('Modules'):WaitForChild('Compilers', 1); -- Yield forever if missing (learn your lesson)
script:FindFirstChild('Modules'):WaitForChild('Interpreters', 1); -- Yield forever if missing (learn your lesson)

local Modules : Folder = script:FindFirstChild('Modules');
--------------------------
local Interpreters : Folder = Modules:FindFirstChild('Interpreters');
local Compilers : Folder = Modules:FindFirstChild('Compilers');
--------------------------
local HttpService : HttpService = game:GetService("HttpService");
local RunService : RunService = game:GetService("RunService");
--------------------------

Interpreters:WaitForChild('Rerubi');
Interpreters:WaitForChild('FiOne');

Compilers:WaitForChild('Yueliang');

local Rerubi = require(Interpreters:FindFirstChild('Rerubi'));
local FiOne = require(Interpreters:FindFirstChild('FiOne'));

local Yueliang = require(Compilers:FindFirstChild('Yueliang'));

local Init = require(script:FindFirstChild('Init'));
local ConnectionGui = script:FindFirstChild('ConnectionGui');

local DecimalMS : NumberValue = ConnectionGui:FindFirstChild('DecimalMS');
local ConnectedBoolValue : BoolValue = ConnectionGui:FindFirstChild('Connected');
--------------------------
-- Check if HTTP is enabled. --
local HTTP_ENABLED : boolean? = pcall(function() 
    HttpService.GetAsync(HttpService, 'https://www.google.com');
end);

if rawequal(HTTP_ENABLED, false) then
    task.spawn(error, '[WE]: Module cannot load due to the fact of HTTP Requests being disabled.', 2);
    do return '[WE]: Module cannot load due to the fact of HTTP Requests being disabled.' end; -- End the scope.
end
--------------------------
-- Type Checking --
export type WebMethod = "queue" | "job"; -- Queue : Stack Queue | Job : Better than queue --
export type InterpreterMethod = "rerubi" | "fione"; -- Rerubi : Rerubi | Fione: Fione --

export type WebSettings = 
{
        ExecutionMethod: string? | WebMethod,
        ExecutionInterpreter: string? | InterpreterMethod,
        BackendURL: string?,
}; -- Settings (arguments for the WebExecution:Start function) --
--------------------------
local POLLING_CONNECTIONS: {[any]: RBXScriptConnection} = {}; -- Table with RBXSCRIPTCONNECTIONS, so I can disconnect a connection if the Execution is terminated. --
local IS_CONNECTION_ACTIVE : boolean = false; -- Whether there is an connection and the process of long-polling is already happening. --
local HOST_CONNECTION_URL : string; -- Host URL (will be cached). --
local CONNECTION_TIMEOUT : number = 10; -- Timeout delay. --
local CONNECTION_POLLING_DELAY : number = 0.25; -- Delay to wait before re-sending a request. --

local ASSERT_CHECKS : boolean = true; -- Not really assert checks, but rather if checks. --
local DEBUG_MODE : boolean = false; -- Debug everything that happens when initializing the module. --
local CUSTOM_FUNCTIONS : boolean = true; -- Custom Luau Handicapped functions. --
local FAST_EXECUTION : boolean = true; -- Faster execution. Recommended: on. if too many scripts are in the queue (such as 50, your game MIGHT freeze). --
--------------------------
-- 500 Requests per minute => 1 req per 2 seconds => 60 seconds = 30 req
-- 120 Seconds = 60 req
-- 180 Seconds = 90 req

-- 500 requests perminute => 1 req per 1 second => 60 seconds = 60 requests
-- 500 Seconds = 500 requests (60 reqs per min => 120 reqs per min if POLLING_DELAY: 0.5)
-- 340 reqs per min if POLLING_DELAY: 0.25
--------------------------
local ERRORS : {[any]: string?} =
{
        ALREADY_CONNECTED = "[WE]: Already connected to host: %s!",
        CONNECTION_EXISTS = "[WE]: RBXScriptConnection for Long-Polling is already connected! Please use the :Terminate() task on the returned metatable after you have done WebExecution:Start() to stop the connection!",
        DATA_MISSING = "[WE]: Data missing! Expected table with data, got nil!",
        KEY_MISSING = "[WE]: Key \"%s\" expected, got nothing!",
};
local ENDPOINTS : {[any]: string?} =
{
        ADD_TO_QUEUE = "addqueue"; -- Modify to your actual endpoint. addqueue is by default if you will use the back-end source provided by me. REQUEST: POST
        GET_QUEUE = "getqueue"; -- Modify to your actual endpoint. getqueue is by default ifyou will use the back-end source provided by me. REQUEST: GET
};
--------------------------
WebExecution = {};
--------------------------
function WebExecution:Start(Settings : WebSettings?) : ({
    Terminate: Function, -- PLZ ROBLOX PLZ ADD SUPPORTTTTTTTTTTTTTTTTTT FOR FUNCTIONS IN TYPE-CHECKING
    Connection: RBXScriptConnection
    })
    -- Assert checks --
    -- tip: well not assert but if checks
    if ASSERT_CHECKS then 
        if not Settings then
            if DEBUG_MODE then 
                task.spawn(print, "[WE]: An error occured!");
            end;
            return task.spawn(error, ERRORS.DATA_MISSING, 2);--{return}:thread
        end;
        if not rawget(Settings, 'BackendURL') then 
            if DEBUG_MODE then 
                task.spawn(print, "[WE]: An error occured!");
            end;
            return task.spawn(error, string.format(ERRORS.KEY_MISSING, 'BackendURL'), 2);--{return}:thread
        end
        if not rawget(Settings, 'ExecutionInterpreter') then 
            if DEBUG_MODE then 
                task.spawn(print, "[WE]: An error occured!");
            end;
            return task.spawn(error, string.format(ERRORS.KEY_MISSING, 'ExecutionInterpreter'), 2);--{return}:thread
        end
        if not rawget(Settings, 'ExecutionMethod') then
            if DEBUG_MODE then 
                task.spawn(print, "[WE]: An error occured!");
            end;
            return task.spawn(error, string.format(ERRORS.KEY_MISSING, 'ExecutionMethod'), 2);--{return}:thread
        end
    end;
    
    -- Connection checks --
    if rawequal(IS_CONNECTION_ACTIVE, true) then
        if DEBUG_MODE then 
            task.spawn(print, "[WE]: Connection is already active!");
        end;
        return task.spawn(error, string.format(ERRORS.ALREADY_CONNECTED, HOST_CONNECTION_URL), 2);--{return}:thread
    end;
    if rawlen(POLLING_CONNECTIONS) > 0 then
        if DEBUG_MODE then 
            task.spawn(print, "[WE]: There's a connection already!");
        end;
        return task.spawn(error, ERRORS.CONNECTION_EXISTS, 2);--{return}:thread
    end;
    -- Connection timeout checking --
    
    -- i wouldn't really call this timeout since  it won't time out but stop the script from further execution if the response time was like 5000 seconds
    
    local Start : number = os.clock(); -- Has support for decimal points (unlike os.time 💀)
    
    pcall(HttpService.GetAsync, HttpService, rawget(Settings, 'BackendURL'));
    
    local End : number = os.clock() - Start;
    
    if End >= CONNECTION_TIMEOUT then
        if DEBUG_MODE then 
            task.spawn(print, "[WE]: Connection timeout expired!");
        end;
        task.spawn(error, '[WE]: Connection timeout expired!', 2);
        do return end; -- End the scope.
    end;
    
    -- RBXScriptConnection --
    --[=[
    table.insert(POLLING_CONNECTIONS, RunService.Heartbeat:Connect(function()
        IS_CONNECTION_ACTIVE = true;

        local Backend : string = rawget(Settings, 'BackendURL');
        if Backend and rawlen(Backend) > 0 and string.match(Backend, 'http(.+)://(%w+).(%w+).(%w+)') then
            HOST_CONNECTION_URL = tostring(Backend);
        end;
        local Interpreter : InterpreterMethod = rawget(Settings, 'ExecutionInterpreter');
        --[[
        if tostring(string.lower(Interpreter)) ~= 'fione' or tostring(string.lower(Interpreter)) ~= 'rerubi' then
            if DEBUG_MODE then 
                task.spawn(print, "[WE]: Invalid Interpreter provided!");
            end;
            task.spawn(error, `[WE]: Expected existing interpreter (fione | rerubi), got: {tostring(Interpreter)}`, 2);
        end;
        ]]
        local Method  : WebMethod = rawget(Settings, 'ExecutionMethod');
        --[[
        if tostring(string.lower(Method)) ~= 'queue' or tostring(string.lower(Interpreter)) ~= 'job' then
            if DEBUG_MODE then 
                task.spawn(print, "[WE]: Invalid execution method provided!");
            end;
            task.spawn(error, `[WE]: Expected valid execution method (queue | job), got: {tostring(Method)}`, 2);
        end;
        ]]
        if Method == "queue" then 
            -- QUEUE METHOD --

            local FullURL : string = `{Backend}/{ENDPOINTS.GET_QUEUE}`;


            pcall(function() 
                local Response : string = HttpService:GetAsync(FullURL);
                local DecodedResponse = HttpService:JSONDecode(Response);
                DecodedResponse = DecodedResponse.scriptQueue or {};



                if rawlen(DecodedResponse) > 0 then
                    for index, value in ipairs(DecodedResponse) do
                        if DEBUG_MODE then
                            print(`\n[WE]: Executing script\n[index]: {index} | [script]: {value}`);
                        end;
                        local Success, Error = pcall(function()
                            local BC = Yueliang(value); -- Expected start signature: \x1bLua

                            local CleanEnvironment;

                            local Module = script:FindFirstChild('CleanEnv'):Clone();
                            CleanEnvironment = getfenv(debug.info(require(Module), 'f'));
                            Module:Destroy();

                            if Interpreter == "fione" then
                                local NewState = FiOne.bc_to_state(BC);
                                local Closure = FiOne.wrap_state(NewState, CleanEnvironment);

                                if rawequal(CUSTOM_FUNCTIONS, true) then
                                    Init(getfenv(Closure)); -- Initialize the closure environment.
                                end

                                if rawequal(FAST_EXECUTION, true) then
                                    task.spawn(function() 
                                        local Suc, Err = pcall(Closure);
                                    end); -- Task scheduler > all
                                else
                                    local Suc, Err = pcall(Closure);
                                end

                            elseif Interpreter == "rerubi" then
                                local Closure, Buffer = Rerubi(BC);

                                if rawequal(CUSTOM_FUNCTIONS, true) then
                                    Init(getfenv(Closure)); -- Initialize the closure environment.
                                end;

                                if rawequal(FAST_EXECUTION, true) then
                                    task.spawn(function()
                                        local Suc, Err = pcall(Closure);
                                    end); -- Task scheduler > all
                                else
                                    local Suc, Err = pcall(Closure);
                                end
                            end;
                        end);
                    end;
                end;
            end);
        elseif Method == "job" then
            -- Coming soon --
        end;
        if DEBUG_MODE then 
            print("[WE]: Sent request")
        end
        wait(CONNECTION_POLLING_DELAY);
    end));
    ]=]
    IS_CONNECTION_ACTIVE = true;
    coroutine.wrap(function() 
        while true do
            ConnectedBoolValue.Value = IS_CONNECTION_ACTIVE;
            if rawequal(IS_CONNECTION_ACTIVE, false) then
                break;
            end
            local Backend : string = rawget(Settings, 'BackendURL');
            if Backend and rawlen(Backend) > 0 and string.match(Backend, 'http(.+)://(%w+).(%w+).(%w+)') then
                HOST_CONNECTION_URL = tostring(Backend);
            end;
            local Interpreter : InterpreterMethod = rawget(Settings, 'ExecutionInterpreter');
        --[[
        if tostring(string.lower(Interpreter)) ~= 'fione' or tostring(string.lower(Interpreter)) ~= 'rerubi' then
            if DEBUG_MODE then 
                task.spawn(print, "[WE]: Invalid Interpreter provided!");
            end;
            task.spawn(error, `[WE]: Expected existing interpreter (fione | rerubi), got: {tostring(Interpreter)}`, 2);
        end;
        ]]
            local Method  : WebMethod = rawget(Settings, 'ExecutionMethod');
        --[[
        if tostring(string.lower(Method)) ~= 'queue' or tostring(string.lower(Interpreter)) ~= 'job' then
            if DEBUG_MODE then 
                task.spawn(print, "[WE]: Invalid execution method provided!");
            end;
            task.spawn(error, `[WE]: Expected valid execution method (queue | job), got: {tostring(Method)}`, 2);
        end;
        ]]
            if Method == "queue" then 
                -- QUEUE METHOD --

                local FullURL : string = `{Backend}/{ENDPOINTS.GET_QUEUE}`;


                pcall(function()
                    
                    local StartMS : number = os.clock();
                    
                    local Response : string = HttpService:GetAsync(FullURL);
                    
                    local EndMS : number = (os.clock() - StartMS) * 100;
                    DecimalMS.Value = EndMS;
                    
                    local DecodedResponse = HttpService:JSONDecode(Response);
                    DecodedResponse = DecodedResponse.scriptQueue or {};



                    if rawlen(DecodedResponse) > 0 then
                        for index, value in ipairs(DecodedResponse) do
                            if DEBUG_MODE then
                                print(`\n[WE]: Executing script\n[index]: {index} | [script]: {value}`);
                            end;
                            local Success, Error = pcall(function()
                                local BC = Yueliang(value); -- Expected start signature: \x1bLua

                                local CleanEnvironment;

                                local Module = script:FindFirstChild('CleanEnv'):Clone();
                                CleanEnvironment = getfenv(debug.info(require(Module), 'f'));
                                Init(CleanEnvironment);
                                Module:Destroy();

                                if Interpreter == "fione" then
                                    local NewState = FiOne.bc_to_state(BC);
                                    local Closure = FiOne.wrap_state(NewState, CleanEnvironment);

                                    if rawequal(CUSTOM_FUNCTIONS, true) then
                                        Init(getfenv(Closure)); -- Initialize the closure environment.
                                    end

                                    if rawequal(FAST_EXECUTION, true) then
                                        task.spawn(function() 
                                            local Suc, Err = pcall(Closure);
                                        end); -- Task scheduler > all
                                    else
                                        local Suc, Err = pcall(Closure);
                                        if not Suc then 
                                            task.spawn(warn, `[WE]: Error occured! Error: {tostring(Err)}`);
                                        end
                                    end

                                elseif Interpreter == "rerubi" then
                                    local Closure, Buffer = Rerubi(BC);

                                    if rawequal(CUSTOM_FUNCTIONS, true) then
                                        Init(getfenv(Closure)); -- Initialize the closure environment.
                                    end;

                                    if rawequal(FAST_EXECUTION, true) then
                                        task.spawn(function()
                                            local Suc, Err = pcall(Closure);
                                        end); -- Task scheduler > all
                                    else
                                        local Suc, Err = pcall(Closure);
                                        if not Suc then 
                                            task.spawn(warn, `[WE]: Error occured! Error: {tostring(Err)}`);
                                        end
                                    end
                                end;
                            end);
                        end;
                    end;
                end);
            elseif Method == "job" then
                -- Coming soon --
            end;
            if DEBUG_MODE then 
                print("[WE]: Sent request")
            end
            wait(CONNECTION_POLLING_DELAY);
        end;
    end)();
    
    return setmetatable({
        Terminate = function()
            if rawlen(POLLING_CONNECTIONS) > 0 then
                for index, val in ipairs(POLLING_CONNECTIONS) do
                    val:Disconnect();
                    POLLING_CONNECTIONS[index] = nil;
                end;
            end;
            IS_CONNECTION_ACTIVE = false;
            HOST_CONNECTION_URL = nil;
        end,
        Connection = POLLING_CONNECTIONS[1] or nil,
    }, {
        __metatable = 'This metatable is locked.',
        __newindex = function(self, key, value) return task.spawn(error, '[WE]: You cannot modify an protected table!'); end;
    })
end;

return WebExecution;
