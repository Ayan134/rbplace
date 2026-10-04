--[[
	ClientMain
	Boots every client controller. Controllers receive the shared registry in Init()
	so they can talk to each other without circular requires.
]]

local Controllers = script.Parent:WaitForChild("Controllers")

local order = {
	"DataController",
	"SoundManager",
	"LightingController",
	"StickerRenderer",
	"EffectsController",
	"AnimationController",
	"FirstPersonController",
	"CameraController",
	"InteractionController",
	"PeelController",
	"BagController",
	"ShopDisplayController",
	"UIController",
}

local registry = {}
for _, name in ipairs(order) do
	registry[name] = require(Controllers:WaitForChild(name))
end

for _, name in ipairs(order) do
	local controller = registry[name]
	if controller.Init then
		controller.Init(registry)
	end
end

for _, name in ipairs(order) do
	local controller = registry[name]
	if controller.Start then
		task.spawn(controller.Start)
	end
end
