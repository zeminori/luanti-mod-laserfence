core.register_node("laserfence:laser", {
	description = "LaserFence laser",
	tiles = {
		"laserfence_laser_top.png", "laserfence_laser_bot.png",
		"laserfence_laser_side.png", "laserfence_laser_side.png",
		"laserfence_laser_side.png", "laserfence_laser_front.png"
	},
	paramtype2 = "facedir",
	groups = {cracky=2},
	mesecons = {effector = {
		action_on = function (pos, node)
			local facedir = node.param2
			local dir = -core.facedir_to_dir(facedir)
			local length = tonumber(core.settings:get("laserfence.length")) or 64
			local pos1 = pos+dir
			local maxpos = pos + dir*length
			local ray = core.raycast(pos1, maxpos, false, false, false)
			local pt = ray:next()
			if pt and pt.under then
				local pos2 = pt.under
				local onode = core.get_node(pos2)
				if onode.name == "laserfence:receiver" then
					local i = 0
					local limit = vector.distance(pos1, pos2)
					repeat
						local ipos = pos1+dir*i
						local inode = core.get_node(ipos) or {name = ""}
						if inode.name ~= "laserfence:beam" then
							core.set_node(ipos, {name = "laserfence:beam", param2 = facedir})
							local bmeta = core.get_meta(ipos)
							bmeta:set_string("laser_pos", core.pos_to_string(pos))
						end
						i = i+1
					until inode.name == "laserfence:receiver" or i >= limit
					local lmeta = core.get_meta(pos)
					lmeta:set_int("active",1)
				end
			end
		end,
		action_off = function (pos, node)
			local facedir = node.param2
			local dir = -core.facedir_to_dir(facedir)
			local pos1 = pos+dir
			local i = 0
			repeat
				local ipos = pos1+dir*i
				local inode = core.get_node(ipos) or {name = ""}
				if inode.name == "laserfence:beam" then
					core.remove_node(ipos)
				end
				i = i+1
			until inode.name ~= "laserfence:beam"
			local lmeta = core.get_meta(pos)
			lmeta:set_string("active","")
		end,
	}}
})

core.register_node("laserfence:receiver", {
	description = "LaserFence receiver",
	tiles = {"laserfence_receiver.png"},
	groups = {cracky=2},
})

local beamtxt = "[fill:1x1:1,1:" ..
(core.settings:get("laserfence.color") or "yellow") .. "^[opacity:170"
core.register_node("laserfence:beam", {
	description = "LaserFence beam",
	tiles = {beamtxt, beamtxt, beamtxt, beamtxt, "blank.png", "blank.png"},
	use_texture_alpha = true,
	can_dig = function() return false end,
	groups = {not_in_creative_inventory=1, unbreakable=1, bouncy = tonumber(core.settings:get("laserfence.bouncy")) or 90},
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.1, -0.1, -0.5, 0.1, 0.1, 0.5},
		},
	},
	paramtype = "light",
	light_source = tonumber(core.settings:get("laserfence.light_source")) or 14,
	paramtype2 = "facedir",
	damage_per_second = tonumber(core.settings:get("laserfence.damage")) or 3,
})

core.register_abm({
    label = "Remove orphan beams",
    nodenames = {"laserfence:beam"},
    interval = 10,
	chance = 1,
    action = function(pos, node)
		local bmeta = core.get_meta(pos)
		local lposstr = bmeta and bmeta:get("laser_pos")
		local lpos = lposstr and core.string_to_pos(lposstr)
		if lpos then
			local node = core.get_node(lpos) or {name = ""}
			if node.name == "laserfence:laser" then
				local lmeta = core.get_meta(lpos)
				if lmeta:get("active") then
					return
				end
			end
		end
		core.remove_node(pos)
	end
})


core.register_craft({
	output = "laserfence:laser",
	recipe = {
		{"default:steelblock","default:steelblock","default:steelblock"},
		{"default:obsidian_glass","default:mese","default:steelblock"},
		{"default:steelblock","default:steelblock","default:steelblock"}
	}
})

core.register_craft({
	output = "laserfence:receiver",
	recipe = {
		{"default:steelblock","default:obsidian","default:steelblock"},
		{"default:obsidian","default:steelblock","default:obsidian"},
		{"default:steelblock","default:obsidian","default:steelblock"}
	}
})
