# WebExecution

#### Roblox Script execution, on your **Web Browser**!

# Files
#### Lua files (base source code) can be accessed in the lua folder, while the rbxm folder provides the actual RBXM with everything set-up.

# Usage
```lua
local WebExecution = require(workspace.WebExecution);
local Start = WebExecution:Start({
    ExecutionMethod = "queue"; -- Methods (queue / job)
    ExecutionInterpreter = "fione"; -- (FiOne / Rerubi)
    BackendURL = ""; -- Backend URL
});

task.wait(15);
Start.Terminate();
```

# Setting Up
#### To set it up, you must host the back-end so the express server can successfully handle post/get requests, then you can also use the executor.html that is supplied in the backend files.
#### Then, run these _**commands**_.
```bash
    npm install express body-parser
```
```js
    node index.js
```
# Description
#### Short-story, just an web based executor which uses the long-polling method in roblox to achieve "server giving client data" since it isn't yet possible in roblox to use websockets or anything websocket related. This web executor was made in 3 hours in a rush, and it's meant to be used for 1 player only. You can adapt it to several users using it, and it even has it's custom settings.

#### Settings:
- Connection:
```lua
CONNECTION_TIMEOUT = 10; -- Connection time-out. --
CONNECTION_POLLING_DELAY = 0.25; -- Connection polling delay. --
-- to explain it shortly, if you lower the polling delay even down, the execution will be quick but there's a chance that you will get ratelimited. The max amount of requests you can send per minute is 500, so 4 requests = 1 second => 60 seconds = 240, meaning you can lower it down to 0.125 and not risk getting ratelimited. --
ASSERT_CHECKS = true; -- Self explanatory. --
DEBUG_MODE = false; -- Keep it as false if you don't want 500 prints each second. --
CUSTOM_FUNCTIONS = true; -- This will use the init module to set indexes in the cleaned environment to key values such as custom functions, etc... (you can add as many as you like)
FAST_EXECUTION = true; -- Self explanatory. --
```
- Endpoints:
```lua
local ENDPOINTS : {[any]: string?} =
{
        ADD_TO_QUEUE = "addqueue"; -- Modify to your actual endpoint. addqueue is by default if you will use the back-end source provided by me. REQUEST: POST
        GET_QUEUE = "getqueue"; -- Modify to your actual endpoint. getqueue is by default ifyou will use the back-end source provided by me. REQUEST: GET
};
```
#### API
```lua
  function WebExecution:Start(Settings: WebSettings?): ({Terminate = function, Connection: RBXScriptConnection or nil})
  - params:
  Settings: table
  - returns:
  Data: table
  {
  Terminate: function() <-- sets the upvalue "IS_CONNECTION_ACTIVE" to false so it will break the while loop if there is one. (i had to adapt from a heartbeat loop to a while loop since you couldn't really make the heartbeat really wait the polling delay.
  Connection: nil <-- switched from a heartbeat connection to a while loop
  }
```
# Credits
- ### [Rerumu](https://github.com/Rerumu) (bytecode interpreters, such as fione or rerubi)
- ### [MoonShine](https://github.com/gamesys/moonshine) (bytecode compilers such as yueliang)
- ### [Zirt](https://discord.com/users/1142785342919938128) (coding / gui)
