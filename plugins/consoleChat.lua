---@type Plugin
local plugin = ...
plugin.name = "ConsoleChat";
plugin.author = "gart"
local commandStruct = {
    info = "Used for in-console chatting",
    usage = "<message>",
    canCall = function(ply) return ply:IsConsole() end,
    call = function() return end
}
plugin.commands["-"] = commandStruct
plugin.commands["--"] = commandStruct
plugin.commands["---"] = commandStruct
plugin.commands["#"] = commandStruct
plugin.commands["##"] = commandStruct
plugin.commands["###"] = commandStruct
plugin.commands["."] = commandStruct
plugin.commands[".."] = commandStruct
plugin.commands["..."] = commandStruct
