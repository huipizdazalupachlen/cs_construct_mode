AddCSLuaFile();

-- if ( CLIENT ) then return end

include("csgo_s_precache.lua")

CreateConVar("csgo_s_enable" , "1" , "","", 0 , 1)
CreateConVar("csgo_s_enable_npcs" , "1" , "","", 0 , 1)
CreateConVar("csgo_s_volume_helmet" , "0.45" , "","", 0, 1)
CreateConVar("csgo_s_volume_headshot_noarmor" , "1" , "","", 0, 1)
CreateConVar("csgo_s_volume_headshot_kill" , "1" , "","", 0, 1)
CreateConVar("csgo_s_volume_bodyshot_kevlar" , "1" , "","", 0, 1)
CreateConVar("csgo_s_sparks" , "any" , "","", 0, 1)

csgo_s_enable 					= GetConVar("csgo_s_enable")
csgo_s_enable_npcs 				= GetConVar("csgo_s_enable_npcs")
csgo_s_volume_helmet			= GetConVar("csgo_s_volume_helmet")
csgo_s_volume_headshot_noarmor	= GetConVar("csgo_s_volume_headshot_noarmor")
csgo_s_volume_headshot_kill		= GetConVar("csgo_s_volume_headshot_kill")
csgo_s_volume_bodyshot_kevlar	= GetConVar("csgo_s_volume_bodyshot_kevlar")
csgo_s_sparks					= GetConVar("csgo_s_sparks")

if ( SERVER ) then

	function CSGO_S_NPC_HELMET_HEADSHOT( ent , hitgroup , dmginfo )
		if not IsValid( ent ) or ent:IsPlayer() == true or csgo_s_enable:GetInt() == 0 or csgo_s_sparks:GetString() == "combine only" then return 
		end
		
		local attacker					=	dmginfo:GetAttacker()
		local plyangle					=	90
		local dmgpos					=	dmginfo:GetDamagePosition()
		
		if hitgroup == HITGROUP_HEAD then
			
			if not IsValid( attacker ) or attacker:IsPlayer() == true or attacker:IsNPC() and csgo_s_enable_npcs:GetBool() == true then

				if ent:Health() > dmginfo:GetDamage()*2 then									
					ParticleEffect( "impact_helmet_headshot_csgo" , dmginfo:GetDamagePosition(), Angle(plyangle), nil)																
					ent:EmitSound( "headshot_csgo/headshot_csgo.wav" , 75 , 100 , csgo_s_volume_helmet:GetFloat() )				
				end			
			end
			
			if dmginfo:GetDamage()*2 >= ent:Health() then
				
				ParticleEffect( "impact_helmet_headshot_csgo" , dmginfo:GetDamagePosition(), Angle(plyangle), nil)
				ent:EmitSound( "headshot_csgo/headshot_armor_kill.wav" , 75 , 100 , 2 )	
				
			end
			
		end
		
	end

	function CSGO_S_NPC_FLESH_HEADSHOT( ent , hitgroup , dmginfo )
		if not IsValid( ent ) or ent:IsPlayer() == true or csgo_s_enable:GetInt() == 0 or ent:GetClass() == "npc_combine_s" or csgo_s_sparks:GetString () == "any" then return 
		end
			
		-- print( "target health " .. ent:Health() .. " my damage " .. dmginfo:GetDamage()*2 )
		
		local attacker					=	dmginfo:GetAttacker()
		local plyangle					=	90
		local dmgpos					=	dmginfo:GetDamagePosition()
		
		if hitgroup == HITGROUP_HEAD then
			
			if not IsValid( attacker ) or attacker:IsPlayer() == true or attacker:IsNPC() and csgo_s_enable_npcs:GetBool() == true then
													
				if ent:Health() > dmginfo:GetDamage()*2 then
				
					local randomizer = math.random( 1 , 2 )
					ent:EmitSound( "headshot_csgo/headshot_nohelm" .. randomizer .. ".wav" , 75 , 100 , csgo_s_volume_headshot_kill:GetFloat() )					
					
				end	
								
			end
			
		end
		
	end

	function CSGO_S_NPC_COMBINE_HEADSHOT( ent , hitgroup , dmginfo )
		if not IsValid( ent ) or ent:IsPlayer() == true or csgo_s_enable:GetInt() == 0 or csgo_s_sparks:GetString() == "any" then return 
		end
		
		-- print("csgo_s_sparks from npc comb " .. csgo_s_sparks:GetString())
		
		local attacker					=	dmginfo:GetAttacker()
		local plyangle					=	90
		local dmgpos					=	dmginfo:GetDamagePosition()
		
		if hitgroup == HITGROUP_HEAD && ent:GetClass() == "npc_combine_s" then
			
			if not IsValid( attacker ) or attacker:IsPlayer() == true or attacker:IsNPC() and csgo_s_enable_npcs:GetBool() == true then

				if ent:Health() > dmginfo:GetDamage()*2 then									
					ParticleEffect( "impact_helmet_headshot_csgo" , dmginfo:GetDamagePosition(), Angle(plyangle), nil)																
					ent:EmitSound( "headshot_csgo/headshot_csgo.wav" , 75 , 100 , csgo_s_volume_helmet:GetFloat() )				
				end			
			end
			
			if dmginfo:GetDamage()*2 >= ent:Health() then
				
				ParticleEffect( "impact_helmet_headshot_csgo" , dmginfo:GetDamagePosition(), Angle(plyangle), nil)
				ent:EmitSound( "headshot_csgo/headshot_armor_kill.wav" , 75 , 100 , 2 )	
				
			end
			
		end
		
	end

	function CSGO_S_NPC_COMBINE_BODYSHOT( ent , hitgroup , dmginfo )
		if not IsValid( ent ) or ent:IsPlayer() == true or csgo_s_enable:GetInt() == 0 then return 
		end
		
		local attacker					=	dmginfo:GetAttacker()
		local plyangle					=	90
		
		if hitgroup == HITGROUP_CHEST or hitgroup == HITGROUP_STOMACH or hitgroup == HITGROUP_LEFTARM or hitgroup == HITGROUP_RIGHTARM or hitgroup == HITGROUP_GEAR or HITGROUP_GENERIC  then
			
			-- print(ent:GetClass())
			if ( ent:GetClass() == "npc_combine_s" or ent:GetClass() == "npc_metropolice" ) then 
			
				if attacker:IsPlayer() == true or attacker:IsNPC() and csgo_s_enable_npcs:GetBool() == true then
					
					
						local particleSound		=	ents.Create( "env_spark" )
						local randomizer = math.random( 1 , 5 )
						
						particleSound:SetPos( dmginfo:GetDamagePosition() )
						particleSound:Spawn()					
						particleSound:EmitSound( "bodyshot_csgo/kevlar" .. randomizer .. ".wav" , 75 , 100 , csgo_s_volume_bodyshot_kevlar:GetFloat() )	
						
						-- print("bodyshot random " .. randomizer )
						
						timer.Simple( 0.05 , function()
							
							if IsValid( particleSound ) then
								
								particleSound:Remove()
								
							end
							
						end)

				end
				
			end
			
		end
		
	end

	function CSGO_S_ON_NPC_KILL_HEADSHOT( target , hitgroup , dmginfo )

		if not IsValid( target ) or target:IsPlayer() == true or csgo_s_enable:GetInt() == 0 then return 
		end
		
		local attacker				=	dmginfo:GetAttacker()
		
		if hitgroup == HITGROUP_HEAD then
			
			-- print( "ogey 1" )
			
			if attacker:IsPlayer() == true or attacker:IsNPC() and csgo_s_enable_npcs:GetBool() == true then
				
				-- local number = attacker:EntIndex()
				-- local targetnumber = target:EntIndex()
				
				-- -- print( "GetDamage() " .. dmginfo:GetDamage() )
				-- somehow dmginfo:GetDamage() number is halved??
				-- -- print( "Health() " .. target:Health() )
				-- -- print( "GetMaxHealth() " .. target:GetMaxHealth() )
				-- -- print( "GetDamageType() " .. dmginfo:GetDamageType() )
				-- -- print( "" )
				
				if dmginfo:GetDamage()*2 >= target:Health() then
				
					local randomizer = math.random( 1 , 2 )
					target:EmitSound( "headshot_csgo/headshot_nohelm" .. randomizer .. ".wav" , 75 , 100 , csgo_s_volume_headshot_kill:GetFloat() )	
					-- -- print( "nohelm randomizer " .. randomizer )	
					
				end
				
			end
			
		end
		
	end

	function CSGO_S_PLAYER_SHOTS( ply , hitgroup , dmginfo )
		if not IsValid( ply ) or csgo_s_enable:GetInt() == 0 then return 
		end
		
		local attacker					=	dmginfo:GetAttacker()
		
		if hitgroup == HITGROUP_HEAD then
			
			if attacker:IsPlayer() == true or attacker:IsNPC() and csgo_s_enable_npcs:GetBool() == true then
				
				if ply:Armor() < 1 then
				
					local particleSound		=	ents.Create( "env_spark" )
					local randomizer = math.random( 1 , 2 )
					
					particleSound:SetPos( dmginfo:GetDamagePosition() )
					particleSound:Spawn()
					-- ParticleEffect( "blood_impact_headshot_1" , dmginfo:GetDamagePosition(), Angle(plyangle), nil)	
					particleSound:EmitSound( "headshot_csgo/headshot_nohelm" .. randomizer .. ".wav" , 75 , 100 , csgo_s_volume_headshot_noarmor:GetFloat() )	
					
					timer.Simple( 0.05 , function()
						
						if IsValid( particleSound ) then
							
							particleSound:Remove()
							
						end
						
					end)												
					
				elseif ply:Armor() > 0 then
				
				local particleSound		=	ents.Create( "env_spark" )
					local randomizer = math.random( 1 , 2 )
					
					particleSound:SetPos( dmginfo:GetDamagePosition() )
					particleSound:Spawn()
					ParticleEffect( "impact_helmet_headshot_csgo" , dmginfo:GetDamagePosition(), Angle(90), nil)	
					particleSound:EmitSound( "headshot_csgo/headshot_csgo.wav" , 75 , 100 , csgo_s_volume_helmet:GetFloat() )	
					
					timer.Simple( 0.05 , function()
						
						if IsValid( particleSound ) then
							
							particleSound:Remove()
							
						end
						
					end)
				
				end							
																		
			end					
			
		elseif hitgroup == HITGROUP_CHEST or hitgroup == HITGROUP_STOMACH then
			
				if attacker:IsPlayer() == true or attacker:IsNPC() and csgo_s_enable_npcs:GetBool() == true then
					
					if ply:Armor() > 0 then
						local particleSound		=	ents.Create( "env_spark" )
						local randomizer = math.random( 1 , 5 )
						
						particleSound:SetPos( dmginfo:GetDamagePosition() )
						particleSound:Spawn()
						ParticleEffect( "blood_impact_headshot_1" , dmginfo:GetDamagePosition(), Angle(plyangle), nil)	
						particleSound:EmitSound( "bodyshot_csgo/kevlar" .. randomizer .. ".wav" , 75 , 100 , csgo_s_volume_bodyshot_kevlar:GetFloat() )	
						
						-- print("bodyshot random " .. randomizer )
						
						timer.Simple( 0.05 , function()
							
							if IsValid( particleSound ) then
								
								particleSound:Remove()
								
							end
							
						end)
						
					else									
						
					end							
																		
				end
				
		end
		
	end


	function CSGO_S_SAVE_CONVARS()

		local CSGO_S_NewSaveFile = {
		
			csgo_s_enable 					= GetConVar("csgo_s_enable"):GetInt(),
			csgo_s_enable_npcs 				= GetConVar("csgo_s_enable"):GetBool(),
			csgo_s_volume_helmet			= GetConVar("csgo_s_volume_helmet"):GetFloat(),
			csgo_s_volume_headshot_noarmor	= GetConVar("csgo_s_volume_headshot_noarmor"):GetFloat(),
			csgo_s_volume_headshot_kill		= GetConVar("csgo_s_volume_headshot_kill"):GetFloat(),
			csgo_s_volume_bodyshot_kevlar	= GetConVar("csgo_s_volume_bodyshot_kevlar"):GetFloat(),
			csgo_s_sparks					= GetConVar("csgo_s_sparks"):GetString(),
			
		}
		
		file.Write( "csgo_s_convars_data.txt" , util.TableToJSON( CSGO_S_NewSaveFile ) )
		
		print( "saved !!!" )
		
	end

	function CSGO_S_LOAD_DEFAULT_SETTINGS()
	
		csgo_s_enable 					= GetConVar("csgo_s_enable")
		csgo_s_enable_npcs 					= GetConVar("csgo_s_enable_npcs")
		csgo_s_volume_helmet			= GetConVar("csgo_s_volume_helmet")
		csgo_s_volume_headshot_noarmor	= GetConVar("csgo_s_volume_headshot_noarmor")
		csgo_s_volume_headshot_kill		= GetConVar("csgo_s_volume_headshot_kill")
		csgo_s_volume_bodyshot_kevlar	= GetConVar("csgo_s_volume_bodyshot_kevlar")
		csgo_s_sparks					= GetConVar("csgo_s_sparks")
		
		hook.Add( "ScaleNPCDamage" , "CSGO_S_Npc_Helmet_Headshot" , CSGO_S_NPC_HELMET_HEADSHOT )
		hook.Add( "ScaleNPCDamage" , "CSGO_S_Npc_Flesh_Headshot" , CSGO_S_NPC_FLESH_HEADSHOT )
		hook.Add( "ScaleNPCDamage" , "CSGO_S_Npc_Combine_Headshot" , CSGO_S_NPC_COMBINE_HEADSHOT )
		hook.Add( "ScaleNPCDamage" , "CSGO_S_Npc_Combine_Bodyshot" , CSGO_S_NPC_COMBINE_BODYSHOT )	
		hook.Add( "ScaleNPCDamage" , "CSGO_S_On_Npc_Kill_Headshot" , CSGO_S_ON_NPC_KILL_HEADSHOT )	
		hook.Add( "ScalePlayerDamage" , "CSGO_S_Player_Shots" , CSGO_S_PLAYER_SHOTS )	
		
		print("no save file, load default settings")
	
	end

	function CSGO_S_LOAD_CONVARS()

		local CSGO_SaveFile = file.Read( "csgo_s_convars_data.txt" , "DATA" )
		
		if not isstring( CSGO_SaveFile ) then
		
		CSGO_S_LOAD_DEFAULT_SETTINGS()
		
		return end 
		
		CSGO_SaveFile = util.JSONToTable( CSGO_SaveFile )
		
		csgo_s_enable 					= GetConVar("csgo_s_enable")
		csgo_s_enable_npcs 				= GetConVar("csgo_s_enable_npcs")
		csgo_s_volume_helmet			= GetConVar("csgo_s_volume_helmet")
		csgo_s_volume_headshot_noarmor	= GetConVar("csgo_s_volume_headshot_noarmor")
		csgo_s_volume_headshot_kill		= GetConVar("csgo_s_volume_headshot_kill")
		csgo_s_volume_bodyshot_kevlar	= GetConVar("csgo_s_volume_bodyshot_kevlar")
		csgo_s_sparks					= GetConVar("csgo_s_sparks")
		
		-- PrintTable( CSGO_SaveFile )
		
		csgo_s_enable:SetInt(CSGO_SaveFile[ "csgo_s_enable" ])
		csgo_s_enable_npcs:SetBool(CSGO_SaveFile[ "csgo_s_enable_npcs" ])
		csgo_s_volume_helmet:SetFloat(CSGO_SaveFile[ "csgo_s_volume_helmet" ])
		csgo_s_volume_headshot_noarmor:SetFloat(CSGO_SaveFile[ "csgo_s_volume_headshot_noarmor" ])
		csgo_s_volume_headshot_kill:SetFloat(CSGO_SaveFile[ "csgo_s_volume_headshot_kill" ])
		csgo_s_volume_bodyshot_kevlar:SetFloat(CSGO_SaveFile[ "csgo_s_volume_bodyshot_kevlar" ])
		csgo_s_sparks:SetString(CSGO_SaveFile[ "csgo_s_sparks" ])
		
		print( "convars loaded" )

	end

	timer.Simple( 1 , CSGO_S_LOAD_CONVARS )

	function CSGO_S_HOOKS()
		
		hook.Add( "ScaleNPCDamage" , "CSGO_S_Npc_Helmet_Headshot" , CSGO_S_NPC_HELMET_HEADSHOT )
		hook.Add( "ScaleNPCDamage" , "CSGO_S_Npc_Flesh_Headshot" , CSGO_S_NPC_FLESH_HEADSHOT )
		hook.Add( "ScaleNPCDamage" , "CSGO_S_Npc_Combine_Headshot" , CSGO_S_NPC_COMBINE_HEADSHOT )
		hook.Add( "ScaleNPCDamage" , "CSGO_S_Npc_Combine_Bodyshot" , CSGO_S_NPC_COMBINE_BODYSHOT )	
		hook.Add( "ScaleNPCDamage" , "CSGO_S_On_Npc_Kill_Headshot" , CSGO_S_ON_NPC_KILL_HEADSHOT )	
		hook.Add( "ScalePlayerDamage" , "CSGO_S_Player_Shots" , CSGO_S_PLAYER_SHOTS )	
				
		-- print("csgo headshots loaded ogeyy")
		
	end

	timer.Simple( 1 , CSGO_S_HOOKS )
		
	concommand.Add( "CSGO_S_Save" , CSGO_S_SAVE_CONVARS )
	concommand.Add( "CSGO_S_LoadSave" , CSGO_S_LOAD_CONVARS )

end

if ( CLIENT ) then

	hook.Add( "PopulateToolMenu", "CSGOShotFXSettings", function()

		spawnmenu.AddToolMenuOption( "Options", "CSGO FX","Froze_Menu_CSGOShotFX","CSGO Shot FX", "","", function( panel ) 
		local panelEnable panel:CheckBox( "Enable CSGO Shot FX" , "csgo_s_enable" )
		local panelDisableNPC panel:CheckBox( "Enable for npcs" , "csgo_s_enable_npcs" )
				
		local chooseSpark	= panel:ComboBox( "Sparks setting" , "csgo_s_sparks" )
		chooseSpark:AddChoice("any")
		chooseSpark:AddChoice("combine only")
				
		panel:NumSlider( "Helmet Spark Volume", "csgo_s_volume_helmet", 0, 1 )
		panel:NumSlider( "Headshot Player No Armor Volume", "csgo_s_volume_headshot_noarmor", 0, 1 )
		panel:NumSlider( "Headshot Flesh Volume", "csgo_s_volume_headshot_kill", 0, 1 )
		panel:NumSlider( "Kevlar Bodyshot Volume", "csgo_s_volume_bodyshot_kevlar", 0, 1 )
		
		local button_csgo_s_save = panel:Button( "Save" , "CSGO_S_Save" , "" )
		local button_csgo_s_load = panel:Button( "Load" , "CSGO_S_LoadSave" , "" )
		
		end)

	end )
	
	-- print("ogey toolbear")

end


























