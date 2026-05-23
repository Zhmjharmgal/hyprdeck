local deck_config = {
	master_ratio = 0.60,
	master_direction = "left",
	opposite_direction = "right",
	deck_height = 200,
}

local states_by_workspace = {}

local function workspace_key(ctx)
	for _, target in ipairs(ctx.targets) do
		local workspace = target.window and target.window.workspace
		if type(workspace) == "table" then
			local key = workspace.id or workspace.name
			if key then
				return tostring(key)
			end
		elseif workspace then
			return tostring(workspace)
		end
	end

	local workspace = hl.get_active_workspace()
	if workspace then
		local key = workspace.id or workspace.name
		if key then
			return tostring(key)
		end
	end

	return "__default"
end

local function deck_state_for(ctx)
	local key = workspace_key(ctx)
	states_by_workspace[key] = states_by_workspace[key]
		or {
			curr_master_id = nil,
			curr_slave_id = nil,
			prev_slave_id = nil,
			known_ids = {},
			targets_initialized = false,
		}

	return states_by_workspace[key]
end

local function update_deck_id(deck_state, is_master, new_id)
	if is_master then
		deck_state.curr_master_id = new_id
	else
		deck_state.prev_slave_id = deck_state.curr_slave_id
		deck_state.curr_slave_id = new_id
	end
end

local function remember_targets(ctx, deck_state)
	deck_state.known_ids = {}
	for _, target in ipairs(ctx.targets) do
		deck_state.known_ids[target.window.stable_id] = true
	end
	deck_state.targets_initialized = true
end

local function sync_added_targets(ctx, deck_state)
	if not deck_state.targets_initialized then
		remember_targets(ctx, deck_state)
		return
	end

	local added_id = nil
	local present = {}

	for _, target in ipairs(ctx.targets) do
		local id = target.window.stable_id
		present[id] = true
		if not deck_state.known_ids[id] then
			added_id = id
		end
	end

	deck_state.known_ids = present

	if added_id and #ctx.targets > 1 and added_id ~= deck_state.curr_master_id then
		update_deck_id(deck_state, false, added_id)
	end
end

local function id_exist(ctx, id)
	for _, target in ipairs(ctx.targets) do
		if target.window.stable_id == id then
			return true
		end
	end
	return false
end

local function pre_check(ctx, deck_state)
	local n = #ctx.targets

	if n == 0 or n == 1 then
		return
	end

	local master_exists = id_exist(ctx, deck_state.curr_master_id)
	if not master_exists then
		if id_exist(ctx, deck_state.curr_slave_id) and deck_state.curr_master_id ~= deck_state.curr_slave_id then
			update_deck_id(deck_state, true, deck_state.curr_slave_id)
			for i, target in ipairs(ctx.targets) do
				if target.window.stable_id ~= deck_state.curr_master_id then
					update_deck_id(deck_state, false, ctx.targets[i].window.stable_id)
					break
				end
			end
		else
			update_deck_id(deck_state, true, ctx.targets[1].window.stable_id)
		end
	end

	local slave_exists = id_exist(ctx, deck_state.curr_slave_id)
	if not slave_exists then
		-- hl.notification.create({
		-- 	text = "updating slave id",
		-- 	timeout = 5000,
		-- })
		if id_exist(ctx, deck_state.prev_slave_id) and deck_state.prev_slave_id ~= deck_state.curr_master_id then
			update_deck_id(deck_state, false, deck_state.prev_slave_id)
		else
			for i, target in ipairs(ctx.targets) do
				if target.window.stable_id ~= deck_state.curr_master_id then
					update_deck_id(deck_state, false, ctx.targets[i].window.stable_id)
					break
				end
			end
		end
	end
end

local function find_by_id(ctx, id)
	for i, target in ipairs(ctx.targets) do
		if target.window.stable_id == id then
			return i
		end
	end
	return nil
end

hl.layout.register("hyprdeck", {
	recalculate = function(ctx)
		local n = #ctx.targets
		local deck_state = deck_state_for(ctx)

		if n == 0 then
			remember_targets(ctx, deck_state)
			return
		elseif n == 1 then
			update_deck_id(deck_state, true, ctx.targets[1].window.stable_id)
			remember_targets(ctx, deck_state)
			ctx.targets[1]:place(ctx.area)
			return
		end

		sync_added_targets(ctx, deck_state)

		-- Sanity checks
		-- hl.notification.create({
		-- 	text = "master id: " .. tostring(deck_state.curr_master_id) .. ", slave id: " .. tostring(
		-- 		deck_state.curr_slave_id
		-- 	),
		-- 	timeout = 5000,
		-- })
		pre_check(ctx, deck_state)

		local master_area = ctx:split(ctx.area, deck_config.master_direction, deck_config.master_ratio)
		local slave_area = ctx:split(ctx.area, deck_config.opposite_direction, 1 - deck_config.master_ratio)

		if n == 2 then
			ctx.targets[find_by_id(ctx, deck_state.curr_master_id)]:place(master_area)
			ctx.targets[find_by_id(ctx, deck_state.curr_slave_id)]:place(slave_area)
		else
			local deck_area = ctx:split(slave_area, "top", deck_config.deck_height / slave_area.h)
			local slave_main_area = ctx:split(slave_area, "bottom", 1 - deck_config.deck_height / slave_area.h)

			local deck_n = n - 2
			local deck_grid_width = deck_area.w / deck_n

			for _, target in ipairs(ctx.targets) do
				if target.window.stable_id == deck_state.curr_master_id then
					target:place(master_area)
				else
					if target.window.stable_id == deck_state.curr_slave_id then
						target:place(slave_main_area)
					else
						local ratio = deck_grid_width / deck_area.w
						local gap = ctx:split(deck_area, "left", ratio)
						target:place(gap)
						deck_area = ctx:split(deck_area, "right", 1 - ratio)
					end
				end
			end
		end
	end,

	layout_msg = function(ctx, msg)
		local command = msg:match("^%s*(.-)%s*$")
		local deck_state = deck_state_for(ctx)
		if command == "swapwithmaster master" then
			for _, target in ipairs(ctx.targets) do
				if target.window.active then
					if
						target.window.stable_id ~= deck_state.curr_master_id
						and target.window.stable_id ~= deck_state.curr_slave_id
					then
						update_deck_id(deck_state, false, target.window.stable_id)
					else
						local cmi = deck_state.curr_master_id
						update_deck_id(deck_state, true, deck_state.curr_slave_id)
						update_deck_id(deck_state, false, cmi)
					end
				end
			end
			return true
		end
	end,
})

-- hl.on("window.open", function(w)
-- 	local ws = hl.get_active_workspace()
-- 	if ws and ws.tiled_layout == "lua:deck" and not w.floating then
-- 		hl.dispatch(hl.dsp.layout("on_window_add"))
-- 	end
-- end)
