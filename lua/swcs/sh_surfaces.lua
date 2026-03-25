AddCSLuaFile()

swcs.SurfaceProps = {}
swcs.SurfacePropsReverse = {}
for i = 0, math.huge do
	local strName = util.GetSurfacePropName(i)
	if strName == "" then break end
	strName = strName:lower()

	swcs.SurfaceProps[i] = strName
	swcs.SurfacePropsReverse[strName] = i
end

swcs.SurfaceInfo = {}
function swcs.RegisterSurface(name, data)
	if not name then return end
	if not data then return end

	data.base = data.base and data.base:lower() or nil
	name = name:lower()
	local entry = {}
	local tBase = data.base and swcs.SurfaceInfo[data.base] or nil

	if tBase then
		for k, v in next, tBase do
			entry[k] = v
		end
	else
		entry.penmod = 1.0
		entry.dmgmod = 0.5
	end

	for k, v in next, data do
		entry[k] = v
	end

	swcs.SurfaceInfo[name] = entry
end

function swcs.GetSurfaceInfo(iSurfaceProp)
	local name = swcs.SurfaceProps[iSurfaceProp]
	if name then
		return swcs.SurfaceInfo[name]
	end
end

swcs.RegisterSurface("default", {
	penmod = 1.0,
	dmgmod = 0.5,
})
swcs.RegisterSurface("default_silent", {
	penmod = 1.0,
	dmgmod = 0.5,
})
swcs.RegisterSurface("rock", {
	penmod = 1.0,
	dmgmod = 0.5,
	impact = "impact_rock_csgo",
	decal = "Impact_CSGO.Rock",
})
swcs.RegisterSurface("solidmetal", {
	penmod = 0.3,
	dmgmod = 0.27,
	impact = "impact_metal_csgo",
})
swcs.RegisterSurface("metal", {
	base = "solidmetal",
	penmod = 0.4,
})
swcs.RegisterSurface("dirt", {
	penmod = 0.3,
	dmgmod = 0.6,
	impact = "impact_dirt_csgo",
})
swcs.RegisterSurface("grass", {
	base = "dirt",
	impact = "impact_grass_csgo",
})
swcs.RegisterSurface("plaster", {
	base = "dirt",
	penmod = 0.6,
	dmgmod = 0.7,
	impact = "impact_plaster_csgo",
	decal = "Impact_CSGO.Plaster",
})
swcs.RegisterSurface("concrete", {
	penmod = 0.25,
	dmgmod = 0.5,
	impact = "impact_concrete_csgo",
})
swcs.RegisterSurface("flesh", {
	penmod = 0.9,
	--impact = "impact_flesh_csgo",
})
swcs.RegisterSurface("alienflesh", {
	base = "flesh",
})
swcs.RegisterSurface("plastic_barrel", {
	penmod = 0.7,
	impact = "impact_plastic_csgo",
})
swcs.RegisterSurface("glass", {
	penmod = 0.99,
	impact = "impact_glass_csgo",
})
swcs.RegisterSurface("metalpanel", {
	base = "metal",
	penmod = 0.45,
	dmgmod = 0.5,
})
swcs.RegisterSurface("Plastic_Box", {
	penmod = 0.75,
	impact = "impact_plastic_csgo",
})
swcs.RegisterSurface("plastic", {
	base = "Plastic_Box",

})
swcs.RegisterSurface("Wood", {
	penmod = 0.6,
	dmgmod = 0.9,
	impact = "impact_wood_csgo",
})
swcs.RegisterSurface("combine_metal", {
	base = "metal",
})
swcs.RegisterSurface("wood_crate", {
	base = "wood",
	penmod = 0.9,
})
swcs.RegisterSurface("porcelain", {
	base = "rock",
	penmod = 0.95,
	impact = "impact_concrete_csgo",
})
swcs.RegisterSurface("brick", {
	base = "rock",
	penmod = 0.47,
	impact = "impact_brick_csgo",
	decal = "Impact_CSGO.Brick",
})
swcs.RegisterSurface("metal_box", {
	base = "solidmetal",
	penmod = 0.5,
})
swcs.RegisterSurface("metalvent", {
	base = "metal_box",
	penmod = 0.6,
	dmgmod = 0.45,
})
swcs.RegisterSurface("sand", {
	base = "dirt",
	penmod = 0.3,
	dmgmod = 0.25,
	impact = "impact_sand_csgo",
})
swcs.RegisterSurface("rubber", {
	base = "dirt",
	penmod = 0.85,
	dmgmod = 0.5,
	impact = "impact_rubber_csgo",
	decal = "Impact_CSGO.Rubber",
})
swcs.RegisterSurface("gravel", {
	base = "rock",
	penmod = 0.4,
})
swcs.RegisterSurface("glassbottle", {
	base = "glass",
	penmod = 0.99,
})
swcs.RegisterSurface("pottery", {
	base = "glassbottle",
	penmod = 0.95,
	dmgmod = 0.6,
})
swcs.RegisterSurface("tile", {
	penmod = 0.5,
	dmgmod = 0.4,
	impact = "impact_tile_csgo",
})
swcs.RegisterSurface("stone", {
	base = "rock",
})
swcs.RegisterSurface("wood_solid", {
	base = "wood",
	penmod = 0.8,
})
swcs.RegisterSurface("metalvehicle", {
	base = "metal",
	penmod = 0.5,
})
swcs.RegisterSurface("cardboard", {
	base = "dirt",
	penmod = 0.99,
	dmgmod = 0.95,
	impact = "impact_cardboard_csgo",
	decal = "Impact_CSGO.Cardboard",
})
swcs.RegisterSurface("popcan", {
	base = "metal_box",
})
swcs.RegisterSurface("canister", {
	base = "metalpanel",
})
swcs.RegisterSurface("computer", {
	base = "metal_box",
	penmod = 0.4,
	dmgmod = 0.45,
	impact = "impact_computer_csgo",
})
swcs.RegisterSurface("wood_box", {
	base = "wood",
	penmod = 0.9,
})
swcs.RegisterSurface("wood_plank", {
	base = "wood_box",
	penmod = 0.85,
})
swcs.RegisterSurface("ceiling_tile", {
	base = "cardboard",
})
swcs.RegisterSurface("hay", {
	base = "cardboard",
})
swcs.RegisterSurface("wood_furniture", {
	base = "wood_box",
})
swcs.RegisterSurface("paintcan", {
	base = "popcan",
})
swcs.RegisterSurface("metal_barrel", {
	base = "solidmetal",
	penmod = 0.01,
	dmgmod = 0.01,
})
swcs.RegisterSurface("metalgrate", {
	base = "solidmetal",
	penmod = 0.95,
	dmgmod = 0.99,
})
swcs.RegisterSurface("mud", {
	base = "dirt",
})
swcs.RegisterSurface("carpet", {
	base = "dirt",
	penmod = 0.75,
	impact = "impact_carpet_csgo",
})
swcs.RegisterSurface("wood_panel", {
	base = "wood_crate",
})
swcs.RegisterSurface("snow", {
	penmod = 0.85,
	impact = "impact_snow_csgo",
})
swcs.RegisterSurface("concrete_block", {
	base = "concrete",
})
swcs.RegisterSurface("paper", {
	base = "cardboard",
	impact = "impact_paper_csgo",
})
swcs.RegisterSurface("weapon", {
	base = "metal",
})
swcs.RegisterSurface("boulder", {
	base = "rock",
})
swcs.RegisterSurface("rubbertire", {
	base = "rubber",
})
swcs.RegisterSurface("grenade", {
	base = "metal",
})
