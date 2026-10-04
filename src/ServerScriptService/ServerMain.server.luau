--[[
	ServerMain
	Boots every server service in dependency order: Init() wires remotes and state,
	Start() begins loops and player handling once every service is initialized.
]]

local Services = script.Parent:WaitForChild("Services")

local order = {
	"PlayerDataService",
	"QuestService",
	"EconomyService",
	"UpgradeService",
	"ToolService",
	"ShopService",
	"StickerService",
	"LevelService",
	"PartyService",
}

local loaded = {}
for _, name in ipairs(order) do
	local service = require(Services:WaitForChild(name))
	loaded[name] = service
	if service.Init then
		service.Init()
	end
end

for _, name in ipairs(order) do
	local service = loaded[name]
	if service.Start then
		task.spawn(service.Start)
	end
end

print("[ServerMain] Sticker Peel server started")
