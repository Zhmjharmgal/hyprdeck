local hyprdeck_config = {
	ceo_ratio = 0.60,
	ceo_direction = "left",
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
			ceo_id = nil,
			manager_id = nil,
			prev_manager_id = nil,
			known_ids = {},
			targets_initialized = false,
		}

	return states_by_workspace[key]
end

local function update_role_id(deck_state, is_ceo, new_id)
	if is_ceo then
		deck_state.ceo_id = new_id
	else
		deck_state.prev_manager_id = deck_state.manager_id
		deck_state.manager_id = new_id
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

	if added_id and #ctx.targets > 1 and added_id ~= deck_state.ceo_id then
		update_role_id(deck_state, false, added_id)
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

	local ceo_exists = id_exist(ctx, deck_state.ceo_id)
	if not ceo_exists then
		if id_exist(ctx, deck_state.manager_id) and deck_state.ceo_id ~= deck_state.manager_id then
			update_role_id(deck_state, true, deck_state.manager_id)
			for i, target in ipairs(ctx.targets) do
				if target.window.stable_id ~= deck_state.ceo_id then
					update_role_id(deck_state, false, ctx.targets[i].window.stable_id)
					break
				end
			end
		else
			update_role_id(deck_state, true, ctx.targets[1].window.stable_id)
		end
	end

	local manager_exists = id_exist(ctx, deck_state.manager_id)
	if not manager_exists then
		if id_exist(ctx, deck_state.prev_manager_id) and deck_state.prev_manager_id ~= deck_state.ceo_id then
			update_role_id(deck_state, false, deck_state.prev_manager_id)
		else
			for i, target in ipairs(ctx.targets) do
				if target.window.stable_id ~= deck_state.ceo_id then
					update_role_id(deck_state, false, ctx.targets[i].window.stable_id)
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
			update_role_id(deck_state, true, ctx.targets[1].window.stable_id)
			remember_targets(ctx, deck_state)
			ctx.targets[1]:place(ctx.area)
			return
		end

		sync_added_targets(ctx, deck_state)

		-- Sanity checks
		-- hl.notification.create({
		-- 	text = "CEO id: " .. tostring(deck_state.ceo_id) .. ", manager id: " .. tostring(
		-- 		deck_state.manager_id
		-- 	),
		-- 	timeout = 5000,
		-- })
		pre_check(ctx, deck_state)

		local ceo_area = ctx:split(ctx.area, hyprdeck_config.ceo_direction, hyprdeck_config.ceo_ratio)
		local staff_area = ctx:split(ctx.area, hyprdeck_config.opposite_direction, 1 - hyprdeck_config.ceo_ratio)

		if n == 2 then
			ctx.targets[find_by_id(ctx, deck_state.ceo_id)]:place(ceo_area)
			ctx.targets[find_by_id(ctx, deck_state.manager_id)]:place(staff_area)
		else
			local deck_area = ctx:split(staff_area, "top", hyprdeck_config.deck_height / staff_area.h)
			local manager_area = ctx:split(staff_area, "bottom", 1 - hyprdeck_config.deck_height / staff_area.h)

			local intern_count = n - 2
			local intern_width = deck_area.w / intern_count

			for _, target in ipairs(ctx.targets) do
				if target.window.stable_id == deck_state.ceo_id then
					target:place(ceo_area)
				else
					if target.window.stable_id == deck_state.manager_id then
						target:place(manager_area)
					else
						local ratio = intern_width / deck_area.w
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
		if command == "swapwithmaster master" or command == "promote" then
			for _, target in ipairs(ctx.targets) do
				if target.window.active then
					if
						target.window.stable_id ~= deck_state.ceo_id
						and target.window.stable_id ~= deck_state.manager_id
					then
						update_role_id(deck_state, false, target.window.stable_id)
					else
						local old_ceo_id = deck_state.ceo_id
						update_role_id(deck_state, true, deck_state.manager_id)
						update_role_id(deck_state, false, old_ceo_id)
					end
				end
			end
			return true
		end
	end,
})

-- hl.on("window.open", function(w)
-- 	local ws = hl.get_active_workspace()
-- 	if ws and ws.tiled_layout == "lua:hyprdeck" and not w.floating then
-- 		hl.dispatch(hl.dsp.layout("promote"))
-- 	end
-- end)
