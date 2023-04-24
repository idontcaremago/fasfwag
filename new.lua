-- da hood egg farm
-- yes very shitty code, i dont rlly care its for a dead game cry abt it

-- console was requested
rconsolename("eggfarm.lua ; buki#0001 - ".. string.format("%02i:%02i %s", ((os.date("*t").hour % 24 - 1) % 12) + 1, os.date("*t").min, os.date("*t").hour % 24 < 12 and "AM" or "PM"))
rconsoleprint("@@CYAN@@")

if not game:IsLoaded() then
    rconsoleprint("[*] Awaiting for game to load. \n")
    game.Loaded:Wait()
end

if LOADED then return end
getgenv().LOADED = true;

task.spawn(function()
    game:GetService("CoreGui").RobloxPromptGui.promptOverlay.ChildAdded:Connect(function(v)
        if v.Name == "ErrorPrompt" then
            task.wait(2)
            game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId)
        end
    end)
end)

local QueueOnTeleport = queue_on_teleport or syn.queue_on_teleport
local FoundEggs = false;

QueueOnTeleport([[
  loadstring(game:HttpGet("https://raw.githubusercontent.com/graveyardsuwu/egg1/main/egg", true))();
]])

UserSettings().GameSettings.MasterVolume = 0

local Stats = {0, 0, 0, tick(), 0};

if not isfile("eggfarm-stats.json") then
    writefile("eggfarm-stats.json", game:GetService("HttpService"):JSONEncode(Stats))
end

Stats = game:GetService("HttpService"):JSONDecode(readfile("eggfarm-stats.json"))

local function comma_value(amount) -- not mine, credits to: https://devforum.roblox.com/t/how-would-i-make-a-large-number-have-commas/384427
    local formatted = amount
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1,%2")
        if (k == 0) then
            break
        end
    end
    return formatted
end

local function ConvertToHMS(Seconds)
    local Minutes = (Seconds - Seconds % 60) / 60
    Seconds = Seconds - Minutes * 60
    local Hours = (Minutes - Minutes % 60) / 60
    Minutes = Minutes - Hours * 60
    return string.format("%02i", Hours) .. ":" .. string.format("%02i", Minutes) .. ":" .. string.format("%02i", Seconds)
end

local function FindEggs()
    local FoundEggs = {};
    for i, v in next, game:GetService("Workspace").Ignored:GetChildren() do
        if string.find(v.Name, "Egg") then
            table.insert(FoundEggs, v)
        end
    end
    return FoundEggs
end

local EggAmount = #FindEggs()
Stats[1] = Stats[1] + EggAmount -- adding eggs found to stats

local function CollectEggs()
    for i = 1, 100 do
        if (#FindEggs()) ~= 0 then
            for i, v in next, FindEggs() do
                firetouchinterest(game:GetService("Players").LocalPlayer.Character.HumanoidRootPart, v, 0)
                task.wait()
                firetouchinterest(game:GetService("Players").LocalPlayer.Character.HumanoidRootPart, v, 1)
            end
        end
    end
    return true
end

local function FetchJobIds()
    local Servers = {os.date("!*t").hour};
    local ServerPages;
    repeat
        task.wait()
        local ServersAPI = game:GetService("HttpService"):JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/".. game.PlaceId .."/servers/Public?sortOrder=Asc&limit=100".. (ServerPages and "&cursor=".. ServerPages or "")));
        for i, v in next, ServersAPI["data"] do
            if v["id"] ~= game.PlaceId and v["playing"] ~= v["maxPlayers"] and tonumber(v["playing"]) ~= 0 then
                table.insert(Servers, v["id"])
            end
        end
        ServerPages = ServersAPI.nextPageCursor
    until not ServerPages
    pcall(function()
        writefile("eggfarm-jobids.json", game:GetService("HttpService"):JSONEncode(Servers))
    end)
end

if not isfile("eggfarm-jobids.json") then
    FetchJobIds()
end

local function RandomJobId()
    if game:GetService("HttpService"):JSONDecode(readfile("eggfarm-jobids.json"))[1] ~= os.date("!*t").hour then
        FetchJobIds()
    end
    local JobIds = game:GetService("HttpService"):JSONDecode(readfile("eggfarm-jobids.json"));
    return JobIds[math.random(1, #JobIds)]
end

local function MainFarm()
    if (#FindEggs()) ~= 0 then
        FoundEggs = true;
        rconsoleprint("@@LIGHT_BLUE@@")
        rconsoleprint("[!] ".. (#FindEggs()) .." egg(s) found. \n")
        rconsoleprint("@@CYAN@@")
        rconsoleprint("[*] Awaiting for character to load. \n")
        repeat task.wait() until game:GetService("Workspace").Players:FindFirstChild(game:GetService("Players").LocalPlayer.Name)
        local BeforeEgg = tonumber(game:GetService("Players").LocalPlayer.DataFolder.Currency.Value);
        CollectEggs()
        local AfterEgg = tonumber(game:GetService("Players").LocalPlayer.DataFolder.Currency.Value) - BeforeEgg;
        Stats[2] = Stats[2] + AfterEgg
        if AfterEgg == 0 then
            rconsoleprint("@@LIGHT_GREEN@@")
            rconsoleprint("[!] Collected ".. EggAmount .." egg(s) and gained a skin crate. \n")
            Stats[3] = Stats[3] + 1
        else
            rconsoleprint("@@LIGHT_GREEN@@")
            rconsoleprint("[!] Collected ".. EggAmount .." egg(s) and gained ".. comma_value(AfterEgg) .."$. \n")
        end
    else
        rconsoleprint("@@LIGHT_RED@@")
        rconsoleprint("[!] 0 eggs found inside ".. game.JobId ..". \n")
    end
    return true
end

local function ServerHop()
    local SelectedJobId = RandomJobId();
    rconsoleprint("@@LIGHT_CYAN@@")
    rconsoleprint("[#] Server hopping to ".. SelectedJobId ..". \n")
    game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, SelectedJobId)
    game:GetService("Players").LocalPlayer.OnTeleport:Connect(function(Status)
        if Status == Enum.TeleportState.Failed then
            rconsoleprint("@@LIGHT_RED@@")
            rconsoleprint("[#] Failed to join ".. SelectedJobId .." finding new server. \n")
            game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, RandomJobId())
        end
    end)
end

MainFarm()
Stats[5] = Stats[5] + 1; -- adding server hops to stats 
writefile("eggfarm-stats.json", game:GetService("HttpService"):JSONEncode(Stats))
ServerHop()

if FoundEggs then
    rconsoleprint("@@LIGHT_CYAN@@")
    rconsoleprint("[-] Current farming stats:\n     Eggs collected: ".. comma_value(Stats[1]) .."\n     Money gained: $".. comma_value(Stats[2]) .." \n     Crates opened: ".. comma_value(Stats[3]) .."\n     Servers hopped: ".. comma_value(Stats[5]) .."\n")
end
--
