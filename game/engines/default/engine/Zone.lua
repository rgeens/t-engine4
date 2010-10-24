-- TE4 - T-Engine 4
-- Copyright (C) 2009, 2010 Nicolas Casalini
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.
--
-- Nicolas Casalini "DarkGod"
-- darkgod@te4.org

require "engine.class"
local Savefile = require "engine.Savefile"
local Dialog = require "engine.ui.Dialog"
local Map = require "engine.Map"
local Astar = require "engine.Astar"
local print = function() end

--- Defines a zone: a set of levels, with depth, nps, objects, level generator, ...
module(..., package.seeall, class.make)

--- Setup classes to use for level generation
-- Static method
-- @param t table that contains the name of the classes to use
-- @usage Required fields:
-- npc_class (default engine.Actor)
-- grid_class (default engine.Grid)
-- object_class (default engine.Object)
function _M:setup(t)
	self.map_class = require(t.map_class or "engine.Map")
	self.level_class = require(t.level_class or "engine.Level")
	self.npc_class = require(t.npc_class or "engine.Actor")
	self.grid_class = require(t.grid_class or "engine.Grid")
	self.trap_class = require(t.trap_class or "engine.Trap")
	self.object_class = require(t.object_class or "engine.Object")
end

--- Loads a zone definition
-- @param short_name the short name of the zone to load, if should correspond to a directory in your module data/zones/short_name/ with a zone.lua, npcs.lua, grids.lua and objects.lua files inside
function _M:init(short_name, dynamic)
	self.short_name = short_name
	if not self:load(dynamic) then
		self.level_range = self.level_range or {1,1}
		if type(self.level_range) == "number" then self.level_range = {self.level_range, self.level_range} end
		self.level_scheme = self.level_scheme or "fixed"
		assert(self.max_level, "no zone max level")
		self.levels = self.levels or {}
		if not dynamic then
			self.npc_list = self.npc_class:loadList("/data/zones/"..self.short_name.."/npcs.lua")
			self.grid_list = self.grid_class:loadList("/data/zones/"..self.short_name.."/grids.lua")
			self.object_list = self.object_class:loadList("/data/zones/"..self.short_name.."/objects.lua")
			self.trap_list = self.trap_class:loadList("/data/zones/"..self.short_name.."/traps.lua")
		end

		-- Determine a zone base level
		self.base_level = self.level_range[1]
		if self.level_scheme == "player" then
			local plev = game:getPlayer().level
			self.base_level = util.bound(plev, self.level_range[1], self.level_range[2])
		end
		print("Initiated zone", self.name, "with base_level", self.base_level)
	else
		print("Loaded zone", self.name, "with base_level", self.base_level)
	end
end

--- Leaves a zone
-- Saves the zone to a .teaz file if requested with persistant="zone" flag
function _M:leave()
	if type(self.persistant) == "string" and self.persistant == "zone" then
		savefile_pipe:push(game.save_name, "zone", self)
--		local save = Savefile.new(game.save_name)
--		save:saveZone(self)
--		save:close()
	end
	game.level = nil
end

--- Parses the npc/objects list and compute rarities for random generation
-- ONLY entities with a rarity properties will be considered.<br/>
-- This means that to get a never-random entity you simply do not put a rarity property on it.
function _M:computeRarities(type, list, level, filter, add_level, rarity_field)
	rarity_field = rarity_field or "rarity"
	local r = { total=0 }
	print("******************", level.level)
	for i, e in ipairs(list) do
		if e[rarity_field] and e.level_range and (not filter or filter(e)) then
--			print("computing rarity of", e.name)
			local lev
			if self.level_adjust_level then
				lev = self:level_adjust_level(level)
			else
				lev = self.base_level + (level.level - 1) + (add_level or 0)
			end

			local max = 10000
			if lev < e.level_range[1] then max = 10000 / (3 * (e.level_range[1] - lev))
			elseif e.level_range[2] and lev > e.level_range[2] then max = 10000 / (lev - e.level_range[2])
			end
			local genprob = math.floor(max / e[rarity_field])
			print(("Entity(%30s) got %3d (=%3d / %3d) chance to generate. Level range(%2d-%2s), current %2d"):format(e.name, math.floor(genprob), math.floor(max), e[rarity_field], e.level_range[1], e.level_range[2] or "--", lev))

			-- Generate and store egos list if needed
			if e.egos and e.egos_chance then
				if _G.type(e.egos_chance) == "number" then e.egos_chance = {e.egos_chance} end
				for ie, edata in pairs(e.egos_chance) do
					local etype = ie
					if _G.type(ie) == "number" then etype = "" end
					if not level:getEntitiesList(type.."/"..e.egos..":"..etype) then
						print("Generating specific ego list", type.."/"..e.egos..":"..etype)
						local egos = self:getEgosList(level, type, e.egos, e.__CLASSNAME)
						if egos then
							local egos_prob = self:computeRarities(type, egos, level, etype ~= "" and function(e) return e[etype] end or nil)
							level:setEntitiesList(type.."/"..e.egos..":"..etype, egos_prob)
							level:setEntitiesList(type.."/base/"..e.egos..":"..etype, egos)
						end
					end
				end
			end

			if genprob > 0 then
--				genprob = math.ceil(genprob / 10 * math.sqrt(genprob))
				r.total = r.total + genprob
				r[#r+1] = { e=e, genprob=r.total, level_diff = lev - level.level }
			end
		end
	end
	table.sort(r, function(a, b) return a.genprob < b.genprob end)

	local prev = 0
	local tperc = 0
	for i, ee in ipairs(r) do
		local perc = 100 * (ee.genprob - prev) / r.total
		tperc = tperc + perc
		print(("entity chance %2d : chance(%4d : %4.5f%%): %s"):format(i, ee.genprob, perc, ee.e.name))
		prev = ee.genprob
	end
	print("*DONE", r.total, tperc.."%")

	return r
end

--- Checks an entity against a filter
function _M:checkFilter(e, filter)
	if e.unique and game.uniques[e.__CLASSNAME.."/"..e.unique] then print("refused unique", e.name, e.__CLASSNAME.."/"..e.unique) return false end

	if not filter then return true end
	if filter.ignore and self:checkFilter(e, filter.ignore) then return false end

	if filter.type and filter.type ~= e.type then return false end
	if filter.subtype and filter.subtype ~= e.subtype then return false end
	if filter.name and filter.name ~= e.name then return false end
	if filter.unique and not e.unique then return false end
	if e.checkFilter and not e:checkFilter(filter) then return false end
	if filter.special and not filter.special(e) then return false end
	if filter.max_ood and resolvers.current_level and e.level_range and resolvers.current_level + filter.max_ood < e.level_range[1] then print("Refused max_ood", e.name, e.level_range[1]) return false end

	if e.unique then print("accepted unique", e.name, e.__CLASSNAME.."/"..e.unique) end

	return true
end

--- Return a string describing the filter
function _M:filterToString(filter)
	local ps = ""
	for what, check in pairs(filter) do
		ps = ps .. what.."="..check..","
	end
	return ps
end

--- Picks an entity from a computed probability list
function _M:pickEntity(list)
	if #list == 0 then return nil end
	local r = rng.range(1, list.total)
	for i = 1, #list do
--		print("test", r, ":=:", list[i].genprob)
		if r <= list[i].genprob then
--			print(" * select", list[i].e.name)
			return list[i].e
		end
	end
	return nil
end

--- Gets the possible egos
function _M:getEgosList(level, type, group, class)
	-- Already loaded ? use it
	local list = level:getEntitiesList(type.."/"..group)
	if list then return list end

	-- otehrwise loads it and store it
	list = require(class):loadList(group, true)
	level:setEntitiesList(type.."/"..group, list)

	return list
end

--- Picks and resolve an entity
-- @param level a Level object to generate for
-- @param type one of "object" "terrain" "actor" "trap"
-- @param filter a filter table
-- @param force_level if not nil forces the current level for resolvers to this one
-- @param prob_filter if true a new probability list based on this filter will be generated, ensuring to find objects better but at a slightly slower cost (maybe)
-- @return the fully resolved entity, ready to be used on a level. Or nil if a filter was given an nothing found
function _M:makeEntity(level, type, filter, force_level, prob_filter)
	resolvers.current_level = self.base_level + level.level - 1
	if force_level then resolvers.current_level = force_level end

	local e
	-- No probability list, use the default one and apply filter
	if not prob_filter then
		local list = level:getEntitiesList(type)
		local tries = filter and filter.nb_tries or 500
		-- CRUDE ! Brute force ! Make me smarter !
		while tries > 0 do
			e = self:pickEntity(list)
			if e and self:checkFilter(e, filter) then break end
			tries = tries - 1
		end
		if tries == 0 then return nil end
	-- Generate a specific probability list, slower to generate but no need to "try and be lucky"
	elseif filter then
		local base_list = nil
		if type == "actor" then base_list = self.npc_list
		elseif type == "object" then base_list = self.object_list
		elseif type == "trap" then base_list = self.trap_list
		else return nil end
		local list = self:computeRarities(type, base_list, level, function(e) return self:checkFilter(e, filter) end, filter.add_levels, filter.special_rarity)
		e = self:pickEntity(list)
		print("[MAKE ENTITY] prob list generation", e and e.name, "from list size", #list)
		if not e then return nil end
	-- No filter
	else
		local list = level:getEntitiesList(type)
		e = self:pickEntity(list)
		if not e then return nil end
	end

	if filter then e.force_ego = filter.force_ego end

	e = self:finishEntity(level, type, e, (filter and filter.ego_filter) or (filter and filter.ego_chance))
	e.__forced_level = filter and filter.add_levels

	return e
end

--- Find a given entity and resolve it
-- @return the fully resolved entity, ready to be used on a level. Or nil if a filter was given an nothing found
function _M:makeEntityByName(level, type, name)
	resolvers.current_level = self.base_level + level.level - 1

	local e
	if type == "actor" then e = self.npc_list[name]
	elseif type == "object" then e = self.object_list[name]
	elseif type == "grid" or type == "terrain" then e = self.grid_list[name]
	elseif type == "trap" then e = self.trap_list[name]
	end
	if not e then return nil end

	if e.unique and game.uniques[e.__CLASSNAME.."/"..e.unique] then print("refused unique", e.name, e.__CLASSNAME.."/"..e.unique) return nil end

	e = self:finishEntity(level, type, e)

	return e
end

--- Finishes generating an entity
function _M:finishEntity(level, type, e, ego_filter)
	e = e:clone()
	e:resolve()
	-- Add "ego" properties, sometimes
	if not e.unique and e.egos and (e.force_ego or e.egos_chance) then
		local egos_list = {}

		local ego_chance = 0
		if _G.type(ego_filter) == "number" then ego_chance = ego_filter; ego_filter = nil
		elseif _G.type(ego_filter) == "table" then ego_chance = ego_filter.ego_chance or 0
		else ego_filter = nil
		end

		if not e.force_ego then
			if _G.type(e.egos_chance) == "number" then e.egos_chance = {e.egos_chance} end
			-- Pick an ego, then an other and so until we get no more
			local picked_etype = {}
			local etype = rng.tableIndex(e.egos_chance, picked_etype)
			local echance = etype and e.egos_chance[etype]
			while etype and rng.percent(util.bound(echance + (ego_chance or 0), 0, 100)) do
				picked_etype[etype] = true
				if _G.type(etype) == "number" then etype = "" end
				local egos = level:getEntitiesList(type.."/"..e.egos..":"..etype)

				-- Filter the egos if needed
				if ego_filter then
					local list = {}
					for z = 1, #egos do list[#list+1] = egos[z].e end
					egos = self:computeRarities(type, list, level, function(e) return self:checkFilter(e, ego_filter) end, ego_filter.add_levels, ego_filter.special_rarity)
				end
				egos_list[#egos_list+1] = self:pickEntity(egos)

				if egos_list[#egos_list] then print("Picked ego", type.."/"..e.egos..":"..etype, ":=>", egos_list[#egos_list].name) else print("Picked ego", type.."/"..e.egos..":"..etype, ":=>", #egos_list) end

				etype = rng.tableIndex(e.egos_chance, picked_etype)
				echance = e.egos_chance[etype]
			end
		else
			local name = e.force_ego
			if _G.type(name) == "table" then name = rng.table(name) end
			print("Forcing ego", name)
			local egos = level:getEntitiesList(type.."/base/"..e.egos..":")
			egos_list = {egos[name]}
			e.force_ego = nil
		end

		if #egos_list > 0 then
			for ie, ego in ipairs(egos_list) do
				print("ego", ego.__CLASSNAME, ego.name, getmetatable(ego))
				ego = ego:clone()
				local newname
				if ego.prefix then newname = ego.name .. e.name
				else newname = e.name .. ego.name end
				print("applying ego", ego.name, "to ", e.name, "::", newname, "///", e.unided_name, ego.unided_name)
				ego.unided_name = nil
				-- The ego requested instant resolving before merge ?
				if ego.instant_resolve then ego:resolve(nil, nil, e) end
				ego.instant_resolve = nil
				-- Void the uid, we dont want to erase the base entity's one
				ego.uid = nil
				-- Merge additively but with array appending, so that nameless resolvers are not lost
				table.mergeAddAppendArray(e, ego, true)
				e.name = newname
				e.egoed = true
			end
			-- Re-resolve with the (possibly) new resolvers
			e:resolve()
		end
		e.egos = nil e.egos_chance = nil e.force_ego = nil
	end

	-- Generate a stack ?
	if e.generate_stack then
		local s = {}
		while e.generate_stack > 0 do
			s[#s+1] = e:clone()
			e.generate_stack = e.generate_stack - 1
		end
		for i = 1, #s do e:stack(s[i], true) end
	end

	e:resolve(nil, true)

	return e
end

--- Do the various stuff needed to setup an entity on the level
-- Grids do not really need that, this is mostly done for traps, objects and actors<br/>
-- This will do all the corect initializations and setup required
-- @param level the level on which to add the entity
-- @param e the entity to add
-- @param typ the type of entity, one of "actor", "object", "trap" or "terrain"
-- @param x the coordinates where to add it. This CAN be null in which case it wont be added to the map
-- @param y the coordinates where to add it. This CAN be null in which case it wont be added to the map
function _M:addEntity(level, e, typ, x, y)
	if typ == "actor" then
		-- We are additing it, this means there is no old position
		e.x = nil
		e.y = nil
		if x and y then e:move(x, y, true) end
		level:addEntity(e)
		e:added()
		-- Levelup ?
		if self.actor_adjust_level and e.forceLevelup then
			local newlevel = self:actor_adjust_level(level, e)
			e:forceLevelup(newlevel + (e.__forced_level or 0))
		end
	elseif typ == "projectile" then
		-- We are additing it, this means there is no old position
		e.x = nil
		e.y = nil
		if x and y then e:move(x, y, true) end
		if e.src then level:addEntity(e, e.src)
		else level:addEntity(e) end
		e:added()
	elseif typ == "object" then
		if x and y then level.map:addObject(x, y, e) end
		e:added()
	elseif typ == "trap" then
		if x and y then level.map(x, y, Map.TRAP, e) end
		e:added()
	elseif typ == "terrain" or typ == "grid" then
		if x and y then level.map(x, y, Map.TERRAIN, e) end
	end
	e:check("addedToLevel", level, x, y)
	e:check("on_added", level, x, y)
end

function _M:load(dynamic)
	local ret = true
	-- Try to load from a savefile
	local data = savefile_pipe:doLoad(game.save_name, "zone", nil, self.short_name)
--	local save = Savefile.new(game.save_name)
--	local data = save:loadZone(self.short_name)
--	save:close()

	if not data and not dynamic then
		local f, err = loadfile("/data/zones/"..self.short_name.."/zone.lua")
		if err then error(err) end
		data = f()
		ret = false
	elseif not data and dynamic then
		data = dynamic
		ret = false
	end
	for k, e in pairs(data) do self[k] = e end
	return ret
end

local recurs = function(t)
	local nt = {}
	for k, e in pairs(nt) do if k ~= "__CLASSNAME" then nt[k] = e end end
	return nt
end
function _M:getLevelData(lev)
	local res = table.clone(self, true)
	if self.levels[lev] then
		table.merge(res, self.levels[lev], true)
	end
	-- Make sure it is not considered a class
	res.__CLASSNAME = nil
	return res
end

--- Leave the level, forgetting uniques and such
function _M:leaveLevel(no_close, lev, old_lev)
	-- Before doing anything else, close the current level
	if not no_close and game.level and game.level.map then
		game:leaveLevel(game.level, lev, old_lev)

		if type(game.level.data.persistant) == "string" and game.level.data.persistant == "zone" then
			print("[LEVEL] persisting to zone memory", game.level.id)
			self.memory_levels = self.memory_levels or {}
			self.memory_levels[game.level.level] = game.level
		elseif type(game.level.data.persistant) == "string" and game.level.data.persistant == "memory" then
			print("[LEVEL] persisting to memory", game.level.id)
			game.memory_levels = game.memory_levels or {}
			game.memory_levels[game.level.id] = game.level
		elseif game.level.data.persistant then
			print("[LEVEL] persisting to disk file", game.level.id)
			savefile_pipe:push(game.save_name, "level", game.level)
--			local save = Savefile.new(game.save_name)
--			save:saveLevel(game.level)
--			save:close()
		else
			game.level:removed()
		end

		game.level.map:close()
	end
end

--- Asks the zone to generate a level of level "lev"
-- @param lev the level (from 1 to zone.max_level)
-- @return a Level object
function _M:getLevel(game, lev, old_lev, no_close)
	self:leaveLevel(no_close, lev, old_lev)

	local level_data = self:getLevelData(lev)

	local level
	-- Load persistant level?
	if type(level_data.persistant) == "string" and level_data.persistant == "zone" then
		self.memory_levels = self.memory_levels or {}
		level = self.memory_levels[lev]

		if level then
			-- Setup the level in the game
			game:setLevel(level)
			-- Recreate the map because it could have been saved with a different tileset or whatever
			-- This is not needed in case of a direct to file persistance becuase the map IS recreated each time anyway
			level.map:recreate()
		end
	elseif type(level_data.persistant) == "string" and level_data.persistant == "memory" then
		game.memory_levels = game.memory_levels or {}
		level = game.memory_levels[self.short_name.."-"..lev]

		if level then
			-- Setup the level in the game
			game:setLevel(level)
			-- Recreate the map because it could have been saved with a different tileset or whatever
			-- This is not needed in case of a direct to file persistance becuase the map IS recreated each time anyway
			level.map:recreate()
		end
	elseif level_data.persistant then
		-- Try to load from a savefile
		level = savefile_pipe:doLoad(game.save_name, "level", nil, self.short_name, lev)

		if level then
			-- Setup the level in the game
			game:setLevel(level)
		end
	end

	-- In any cases, make one if none was found
	if not level then
		local popup = Dialog:simplePopup("Generating level", "Please wait while generating the level...", nil, true)
		popup.__showup = nil
		core.display.forceRedraw()

		level = self:newLevel(level_data, lev, old_lev, game)

		game:unregisterDialog(popup)
	end

	-- Clean up things
	collectgarbage("collect")

	return level
end

function _M:getGenerator(what, level, spots)
	assert(level.data.generator[what], "requested zone generator of type "..tostring(what).." but it is not defined")
	assert(level.data.generator[what].class, "requested zone generator of type "..tostring(what).." but it has no class field")
	print("[GENERATOR] requiring", what, level.data.generator and level.data.generator[what] and level.data.generator[what].class)
	return require(level.data.generator[what].class).new(
			self,
			level.map,
			level,
			spots
		)
end

function _M:newLevel(level_data, lev, old_lev, game)
	local map = self.map_class.new(level_data.width, level_data.height)
	if level_data.all_lited then map:liteAll(0, 0, map.w, map.h) end
	if level_data.all_remembered then map:rememberAll(0, 0, map.w, map.h) end

	-- Setup the entities list
	local level = self.level_class.new(lev, map)
	level:setEntitiesList("actor", self:computeRarities("actor", self.npc_list, level, nil))
	level:setEntitiesList("object", self:computeRarities("object", self.object_list, level, nil))
	level:setEntitiesList("trap", self:computeRarities("trap", self.trap_list, level, nil))

	-- Save level data
	level.data = level_data
	level.id = self.short_name.."-"..lev

	-- Setup the level in the game
	game:setLevel(level)

	-- Generate the map
	local generator = require(level_data.generator.map.class).new(
		self,
		map,
		level,
		level_data.generator.map
	)
	local ux, uy, dx, dy, spots = generator:generate(lev, old_lev)
	spots = spots or {}

	for i = 1, #spots do print("[NEW LEVEL] spot", spots[i].x, spots[i].y, spots[i].type, spots[i].subtype) end

	level.default_up = {x=ux, y=uy}
	level.default_down = {x=dx, y=dy}
	level.spots = spots

	-- Generate objects
	if level_data.generator.object and level_data.generator.object.class then
		local generator = self:getGenerator("object", level, spots)
		generator:generate()
	end

	-- Generate traps
	if level_data.generator.trap and level_data.generator.trap.class then
		local generator = self:getGenerator("trap", level, spots)
		generator:generate()
	end

	-- Generate actors
	if level_data.generator.actor and level_data.generator.actor.class then
		local generator = self:getGenerator("actor", level, spots)
		generator:generate()
	end

	-- Add the entities we are told to
	for i = 0, map.w - 1 do for j = 0, map.h - 1 do
		if map.room_map[i] and map.room_map[i][j] and map.room_map[i][j].add_entities then
			for z = 1, #map.room_map[i][j].add_entities do
				local ae = map.room_map[i][j].add_entities[z]
				self:addEntity(level, ae[2], ae[1], i, j)
			end
		end
	end end

	-- Adjust shown & obscure colors
	if level_data.color_shown then map:setShown(unpack(level_data.color_shown)) end
	if level_data.color_obscure then map:setObscure(unpack(level_data.color_obscure)) end

	-- Call a finisher
	if level_data.post_process then
		level_data.post_process(level)
	end

	-- Delete the room_map, now useless
	map.room_map = nil

	-- Check for connectivity from entrance to exit
	local a = Astar.new(map, game:getPlayer())
	if not level_data.no_level_connectivity then
		print("[LEVEL GENERATION] checking entrance to exit A*", ux, uy, "to", dx, dy)
		if ux and uy and dx and dy and (ux ~= dx or uy ~= dy)  and not a:calc(ux, uy, dx, dy) then
			print("Level unconnected, no way from entrance to exit", ux, uy, "to", dx, dy)
			level:removed()
			return self:newLevel(level_data, lev, old_lev, game)
		end
	end
	for i = 1, #spots do
		local spot = spots[i]
		if spot.check_connectivity then
			local cx, cy
			if type(spot.check_connectivity) == "string" and spot.check_connectivity == "entrance" then cx, cy = ux, uy
			elseif type(spot.check_connectivity) == "string" and spot.check_connectivity == "exit" then cx, cy = dx, dy
			else cx, cy = spot.check_connectivity.x, spot.check_connectivity.y
			end

			print("[LEVEL GENERATION] checking A*", spot.x, spot.y, "to", cx, cy)
			if spot.x and spot.y and cx and cy and (spot.x ~= cx or spot.y ~= cy) and not a:calc(spot.x, spot.y, cx, cy) then
				print("Level unconnected, no way from", spot.x, spot.y, "to", cx, cy)
				level:removed()
				return self:newLevel(level_data, lev, old_lev, game)
			end
		end
	end
	return level
end
