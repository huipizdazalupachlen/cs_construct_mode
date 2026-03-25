local rt_Scope -- = GetRenderTarget("_rt_Scope", 1024, 1024)
local rt_viewmodel -- = GetRenderTarget("swcs_rt_vm", 2048, 2048)

hook.Add("PreDrawViewModels", "swcs.rt", function()
	if not rt_Scope then
		rt_Scope = GetRenderTarget("_rt_Scope", ScrW() / 2, ScrH() / 2)
	end

	render.CopyRenderTargetToTexture(rt_Scope)
end)

hook.Add("PostDrawViewModel", "swcs.rt", function()
	if not rt_viewmodel then
		rt_viewmodel = GetRenderTargetEx("swcs_rt_vm", ScrW(), ScrH(), RT_SIZE_DEFAULT, MATERIAL_RT_DEPTH_SHARED, bit.bor(4, 8) --[[ clamps, clampt]], 0, IMAGE_FORMAT_RGBA16161616F)
	end

	render.CopyRenderTargetToTexture(rt_viewmodel)
end)
