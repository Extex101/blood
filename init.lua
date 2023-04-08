local path = minetest.get_modpath(minetest.get_current_modname())
blood = {}
blood.expire = 150--22/(112/60)--Timed to "Another one Bites the Dust" bpm
local files = {
	"pool"
}
for _, file in ipairs(files) do
	dofile(path.."/"..file..".lua")
end


minetest.register_on_player_hpchange(function(player, hp_change, reason)
	if reason.type == "fall" or reason.type == "punch" and hp_change < 0 then
		if hp_change > -2 then return hp_change end
		local pos = player:get_pos()
		local under = {x=pos.x, y=math.ceil(pos.y-10), z=pos.z}
		local ray = minetest.raycast(pos, under, false, false):next()
		if ray then
			minetest.add_entity({x=ray.above.x, y=math.ceil(ray.above.y)+0.51, z=ray.above.z}, "blood", -hp_change)
		end
	end
	return hp_change
end)

local print = minetest.chat_send_all

local function list_to_tex(list)
	local texture = "[combine:32x32"
	for _, spot in ipairs(list) do
		local tex = "=blank.png"
		if spot.num >= 1 then
			tex = "=tracking_blood_"..spot.num..".png"
		end
		texture = texture..":"..spot.x..","..spot.y..tex
	end
	return texture
end

local function solid(pos)
	if not pos then return end
	local newPos = vector.add(pos, {x=0, y=-0.1, z=0})
	local newUp = vector.add(pos, {x=0, y=0.1, z=0})
	local node = minetest.get_node(newPos)
	local def = minetest.registered_nodes[node.name]

	local up = minetest.get_node(newUp)
	local def2 = minetest.registered_nodes[up.name]
	return def.walkable, def2.walkable
end

minetest.register_entity(":blood",{
	initial_properties = {
		visual = "cube",
		textures = {
			"tracking_blood_5.png",
			"tracking_blood_5.png",
			"blank.png",
			"blank.png",
			"blank.png",
			"blank.png",
		},
		physical = true,
		collide_with_objects = false,
		pointable = false,
		visual_size = {x = 2, y = 0.06, z = 2},
		backface_culling = false,
		use_texture_alpha = true,
		collisionbox = {-0.1, 0.02, -0.1, 0.1, 0.03, 0.1},
	},
	on_step = function(self, dtime)

		if not self.timer then self.timer = 0 end
		if not self.timer2 then self.timer2 = 0 end
		if not self.timer3 then self.timer3 = 0 end
		self.timer = self.timer + dtime
		self.timer2 = self.timer2 + dtime
		self.timer3 = self.timer3 + dtime

		local vely = self.object:get_velocity().y
		if vely and vely == 0 then
			self.object:set_velocity({x=0, y=-10, z=0})
		end

		if self.timer > blood.expire+0.5 then
			self.object:remove()--When the timer runs down, remove the blood
		end

		if self.timer2 > 5 then
			local down, up = solid(self.object:get_pos())
			if down and up then
				self.object:remove()
			end
			self.timer2 = 0
		end

		if self.timer3 > blood.expire/23 then
			local texture = "[combine:32x32"
			for _, spot in ipairs(self.texlist) do
				if spot.num > 0 then
					spot.num = spot.num-1
				end
				local tex = "=blank.png"
				if spot.num >= 1 then
					tex = "=tracking_blood_"..spot.num..".png"
				end
				texture = texture..":"..spot.x..","..spot.y..tex
			end
			self.object:set_properties({
				textures = {texture, "blank.png", "blank.png", "blank.png", "blank.png", "blank.png"}
			})

			self.timer3 = 0
		end

	end,
	on_activate = function(self, staticdata)

		local pos = self.object:get_pos()

		self.texlist = {}
		local spots = 15
		if staticdata then
			local static = minetest.deserialize(staticdata)
			if type(tonumber(staticdata)) == "number" then
				spots = staticdata
			elseif static then
				self.timer = static.timer
				self.texlist = static.texlist

				local texture = list_to_tex(self.texlist)
				self.object:set_properties({
					textures = {texture, "blank.png", "blank.png", "blank.png", "blank.png", "blank.png"},
				})
				return
			end
		end


		local texture = "[combine:32x32"

		for i = 0, tonumber(spots) do

			local blood_num = math.floor(math.random(1, math.min(spots*2.5, 22))+0.5)
			local extra = math.ceil((16 - blood_num)/2.8)

			local x = math.floor(math.random(0, 16+extra))
			local y = math.floor(math.random(0, 16+extra))

			texture = texture..":"..x..","..y.."=tracking_blood_"..blood_num..".png"

			table.insert(self.texlist, {x=x, y=y, num=blood_num})
		end
		self.object:set_properties({
			textures = {texture, "blank.png", "blank.png", "blank.png", "blank.png", "blank.png"},
		})

	end,
	get_staticdata = function(self)
		return minetest.serialize({texlist=self.texlist, timer=self.timer})
	end,
})
