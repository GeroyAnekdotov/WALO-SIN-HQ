-- Run through tools/check_story_mode.py with Lua 5.1. No X-Ray engine is used.
local passed = 0
local function test(name, body)
    body()
    passed = passed + 1
    print("SCENARIO PASS: " .. name)
end

local function load_module(source, shared)
    local env = setmetatable({}, {__index = shared})
    local chunk, err = loadstring(source)
    assert(chunk, err)
    setfenv(chunk, env)()
    return env
end

local function world(input)
    input = input or sources
    local s = {warfare = true, story = false, new_game = false, flags = {story_mode_disabled = true},
        now = 20000, writes = {}, spots = {}, added = 0, removed = 0, native_calls = 0,
        effects = {}, owner_alive = true, registry = {}, squads = {}, conditions_calls = 0}
    local g = setmetatable({}, {__index = _G})
    g.printf = function() end
    g.time_global = function() return s.now end
    g.IsWarfare = function() return s.warfare end
    -- Match the preserved Anomaly expression, including early new-game ambiguity.
    g.IsStoryMode = function() return s.new_game and s.story or not s.flags.story_mode_disabled end
    g.has_alife_info = function(key) return s.flags[key] or false end
    g.give_info = function(key) s.flags[key] = true; s.writes[#s.writes + 1] = key end
    g.axr_main = {config = {r_value = function(_, _, key)
        if key == "new_game_faction" then return s.new_game and "greh" or nil end
        if key == "new_game_story_mode" then return s.story and true or nil end
    end}}
    g.ini_sys = {section_exist = function() return s.redone end,
        r_string_ex = function() return "katacomb_smart_terrain" end}
    local actor = {id = function() return 0 end,
        has_info = function(_, key) return s.flags[key] or false end,
        give_info_portion = function(_, key) g.give_info(key) end}
    g.db = {actor = actor, storage = {}}
    g.warfare = {actor_faction = "greh", get_stalker_pop_factor = function() return 2 end}
    g.RegisterScriptCallback = function(name, fn)
        s.callbacks = s.callbacks or {}; s.callbacks[name] = fn
    end
    g.xr_conditions = {toolkit_task_done = function(_, npc, p)
        s.conditions_calls = s.conditions_calls + 1
        if s.native_result ~= nil then return s.native_result end
        if s.native_nil then return nil, "native-extra" end
        return npc and p and s.flags[npc:section() .. "_upgrade_tier_" .. p[1]] or false
    end, task_giver_alive = function() return s.owner_alive end}
    g.level = {
        map_has_object_spot = function(id, spot) return s.spots[id .. spot] and 1 or 0 end,
        map_add_object_spot_ser = function(id, spot) s.spots[id .. spot] = true; s.added = s.added + 1 end,
        map_remove_object_spot = function(id, spot) s.spots[id .. spot] = nil; s.removed = s.removed + 1 end,
    }
    local mine = {id = 10, props = {base = 0, resource = 1, lair = 1, territory = 0},
        default_max_population = 2, max_population = 2, name = function() return "red_smart_terrain_3_2" end}
    local camp = {id = 11, props = {base = 1, resource = 0, lair = 0, territory = 0},
        name = function() return "red_smart_terrain_4_2" end}
    s.mine, s.camp = mine, camp
    s.registry.red_smart_terrain_4_2 = {faction = "greh", protect = true, resurrect = true}
    s.registry.red_smart_terrain_3_2 = {travel_hub = 1}
    g.smart_terrain_warfare = {uniques = {},
        get_main_base_faction = function(name) return s.registry[name] and s.registry[name].faction end,
        set_main_base = function(name, entry) s.registry[name] = entry end}
    g.simulation_objects = {get_props = function() end}
    g.SIMBOARD = {smarts_by_names = {red_smart_terrain_3_2 = mine, red_smart_terrain_4_2 = camp},
        smarts = {[10] = {squads = s.squads}},
        get_smart_by_name = function(_, name) return name == mine:name() and mine or camp end}
    g.alife = function() return {object = function() end, has_info = function(_, _, key) return s.flags[key] end} end
    g.alife_object = function(id) return s.objects and s.objects[id] end
    g.character_community = function() return "greh" end
    g.trade_manager = {
        trade_init = function(npc, path, ...)
            s.native_calls = s.native_calls + 1; s.path = path; s.arg = ...
            return "native-init", "native-extra"
        end,
        update = function(_, value) s.update_arg = value; return "native-update", "extra-update" end,
        get_trade_profile = function() return s.profile end,
    }
    g.xr_logic = {parse_condlist = function(_, _, _, raw) return {raw = raw} end}
    local core = load_module(input.core, g)
    g.zzzzzz_walo_sin_hq_core = core
    core.on_game_start()
    s.core, s.g = core, g
    s.trade = load_module(input.trade, g)
    s.toolkit = load_module(input.toolkit, g)
    function s:npc(name, id, section)
        return {id = function() return id or 1 end, name = function() return name end,
            section = function() return section or name end}
    end
    function s:set_story(value)
        self.story = value; self.flags.story_mode_disabled = not value
    end
    function s:medic()
        local se = {id = 40, alive = true, name = function() return "sim_default_greh_medic1" end,
            character_name = function() return "Test medic" end}
        self.squads[50] = true
        self.objects = {[50] = {squad_members = function()
            local done = false
            return function() if not done then done = true; return {object = se} end end
        end}}
    end
    return s
end

for _, is_new in ipairs({false, true}) do
    for _, warfare in ipairs({false, true}) do
        for _, story in ipairs({false, true}) do
            test(string.format("mode matrix new=%s warfare=%s story=%s", tostring(is_new), tostring(warfare), tostring(story)), function()
                local s = world()
                s.new_game, s.warfare = is_new, warfare
                s:set_story(story)
                if is_new then s.flags.story_mode_disabled = nil end
                assert(s.core.enabled() == (warfare and not story))
                if is_new and not story then assert(s.g.IsStoryMode()) end
                if is_new then s.core.apply_new_game() else s.core.apply_loaded() end
                assert(s.mine.props.base == (warfare and not story and 1 or 0))
                s.trade.on_game_start(); s.toolkit.on_game_start(); s:medic()
                local npc = s:npc("red_greh_trader")
                local result = s.g.trade_manager.trade_init(npc, "original.ltx", "argument")
                assert(result == "native-init" and s.arg == "argument")
                assert(s.path == (warfare and not story and "items\\trade\\trade_walo_greh_mine_trader.ltx" or "original.ltx"))
                s.flags.sim_default_greh_mechanic_upgrade_tier_2 = true
                assert(s.g.xr_conditions.toolkit_task_done(s.g.db.actor, s:npc("red_greh_tech"), {2}) == (warfare and not story))
                s.flags.red_greh_tech_upgrade_tier_1 = true
                s.toolkit.on_game_start(); s.callbacks.actor_on_update()
                assert(#s.writes == (warfare and not story and 1 or 0))
                s.trade.on_game_start(); s.callbacks.actor_on_first_update()
                assert(s.added == (warfare and not story and 1 or 0))
            end)
        end
    end
end

test("unresolved saved mode and missing Core fail closed", function()
    local s = world(); s.flags.story_mode_disabled = nil
    assert(not s.core.enabled())
    s.g.zzzzzz_walo_sin_hq_core = nil
    s.trade.on_game_start(); s.toolkit.on_game_start()
    s.g.trade_manager.trade_init(s:npc("red_greh_trader"), "original")
    assert(s.path == "original")
    s.toolkit.on_game_start(); s.callbacks.actor_on_update()
    assert(#s.writes == 0)
end)

test("recognized ReDone North uses the existing Core exclusion", function()
    local s = world(); s.redone = true
    assert(not s.core.enabled())
    s.trade.on_game_start(); s.toolkit.on_game_start()
    s.g.trade_manager.trade_init(s:npc("red_greh_trader"), "original")
    assert(s.path == "original")
    s.flags.sim_default_greh_mechanic_upgrade_tier_2 = true
    assert(not s.g.xr_conditions.toolkit_task_done(s.g.db.actor, s:npc("red_greh_tech"), {2}))
end)

test("Story toolkit handler preserves nil and multiple native return values", function()
    local s = world(); s:set_story(true); s.native_nil = true
    s.toolkit.on_game_start()
    local a, b = s.g.xr_conditions.toolkit_task_done(s.g.db.actor, s:npc("red_greh_tech"), {1})
    assert(a == nil and b == "native-extra" and s.conditions_calls == 1)
    s.trade.on_game_start()
    a, b = s.g.trade_manager.trade_init(s:npc("red_greh_trader"), "original")
    assert(a == "native-init" and b == "native-extra")
end)

test("toolkit actor and NPC restrictions remain intact; ordinary Story unlocks survive", function()
    local s = world(); s.toolkit.on_game_start()
    s.flags.sim_default_greh_mechanic_upgrade_tier_3 = true
    s.g.warfare.actor_faction = "stalker"
    assert(not s.g.xr_conditions.toolkit_task_done(s.g.db.actor, s:npc("red_greh_tech"), {3}))
    s.g.warfare.actor_faction = "greh"
    assert(not s.g.xr_conditions.toolkit_task_done(s.g.db.actor, s:npc("other_tech"), {3}))
    s:set_story(true); s.flags.red_greh_tech_upgrade_tier_3 = true
    assert(s.g.xr_conditions.toolkit_task_done(s.g.db.actor, s:npc("red_greh_tech"), {3}))
end)

test("repeated starts do not stack the toolkit or trade wrappers", function()
    local s = world(); s.toolkit.on_game_start(); s.trade.on_game_start()
    local condition, trade = s.g.xr_conditions.toolkit_task_done, s.g.trade_manager.trade_init
    for _ = 1, 10 do s.toolkit.on_game_start(); s.trade.on_game_start() end
    assert(s.g.xr_conditions.toolkit_task_done == condition and s.g.trade_manager.trade_init == trade)
    s:set_story(true)
    assert(not s.g.xr_conditions.toolkit_task_done(s.g.db.actor, s:npc("red_greh_tech"), {1}))
    assert(s.conditions_calls == 1)
end)

test("only owned PDA markers are removed in an inactive mode", function()
    local s = world(); s:medic(); s.trade.on_game_start(); s.callbacks.actor_on_first_update()
    assert(s.added == 1)
    s:set_story(true); s.now = s.now + 11000; s.callbacks.actor_on_update()
    assert(s.removed == 1)
    s = world(); s:medic(); s.spots[40 .. "ui_pda2_medic_location"] = true
    s.trade.on_game_start(); s.callbacks.actor_on_first_update(); s:set_story(true)
    s.now = s.now + 11000; s.callbacks.actor_on_update()
    assert(s.added == 0 and s.removed == 0)
end)

test("save changes discard old marker IDs without deleting another save's markers", function()
    local s = world(); s:medic(); s.trade.on_game_start(); s.callbacks.actor_on_first_update()
    s:set_story(true); s.trade.on_game_start(); s.callbacks.actor_on_first_update()
    assert(s.removed == 0)
end)

test("scientific bunker routing and supply synchronization stay Warfare-only", function()
    for _, story in ipairs({false, true}) do
        local s = world(); s:set_story(story)
        s.g.db.storage[1] = {gulag_name = "jup_b41"}
        local raw = "{=actor_goodwill_ge(ecolog:1000)} supplies_3, supplies_1"
        s.profile = {cfg_ltx = "items\\trade\\trade_ecolog_hermann.ltx",
            buy_supplies = {raw = raw}, config = {r_string_ex = function() return raw end}}
        s.trade.on_game_start()
        s.g.trade_manager.trade_init(s:npc("sim_default_greh_trader1"), s.profile.cfg_ltx)
        assert(s.path == s.profile.cfg_ltx)
        assert(s.profile.buy_supplies.raw == (story and raw or raw:gsub("ecolog:", "greh:")))
        local a, b = s.g.trade_manager.update(s:npc("sim_default_greh_trader1"), "refresh")
        assert(a == "native-update" and b == "extra-update" and s.update_arg == "refresh")
    end
end)

test("Core restores HQ, travel hub, capacity, properties and service minima in Story", function()
    local s = world(); s.mine.default_max_population = 3; s.mine.max_population = 3
    s.core.apply_loaded()
    assert(s.registry.red_smart_terrain_3_2.faction == "greh")
    assert(s.mine.default_max_population == 2 and s.mine.props.base == 1)
    assert(s.g.smart_terrain_warfare.uniques.red_smart_terrain_3_2[4] == 1)
    s:set_story(true); s.core.on_walo_start()
    assert(s.registry.red_smart_terrain_3_2.travel_hub == 1 and not s.registry.red_smart_terrain_3_2.faction)
    assert(s.registry.red_smart_terrain_4_2.faction == "greh")
    assert(s.mine.props.base == 0 and s.mine.props.resource == 1 and s.mine.props.lair == 1)
    assert(s.mine.default_max_population == 3 and s.mine.max_population == 3)
    assert(not s.g.smart_terrain_warfare.uniques.red_smart_terrain_3_2)
    s.core.apply_loaded(); assert(s.mine.props.base == 0)
end)

-- Exercise the preserved Anomaly parser and evaluator, not a rewritten grammar.
string.trim = function(str) return str:match("^%s*(.-)%s*$") end
local function task_world(input)
    local s = world(input)
    s.g.AC_ID = 0
    s.g.xr_effects = setmetatable({}, {__index = function(_, name)
        return function() s.effects[#s.effects + 1] = name end
    end})
    local logic = load_module(sources.logic, s.g)
    function s:eval_task(field, fields)
        local text = (fields or sources.task)[field]
        local list = logic.parse_condlist(nil, "sim_default_greh_medic_task_1", field, text)
        return logic.pick_section_from_condlist(self.g.db.actor, self.g.db.actor, list)
    end
    return s
end

test("medic task availability, fail condition and rewards follow the Core mode", function()
    for _, is_new in ipairs({false, true}) do
        for _, warfare in ipairs({false, true}) do
            for _, story in ipairs({false, true}) do
                local s = task_world(); s.new_game, s.warfare = is_new, warfare; s:set_story(story)
                local active = warfare and not story
                assert(s:eval_task("precondition") == (active and "true" or "false"))
                local status = s:eval_task("condlist_0")
                if active then assert(status == nil) else assert(status == "fail") end
                s:eval_task("on_complete")
                assert(#s.effects == (active and 7 or 0))
                assert((s.flags.sim_default_greh_medic_drugkit_done or false) == active)
            end
        end
    end
    local s = task_world(); s.owner_alive = false
    assert(s:eval_task("condlist_0") == "fail")
end)

if sources.baseline then
    test("Warfare Story-OFF probes match the unchanged installed baseline", function()
        local function probe(input)
            local s = task_world(input)
            s.trade.on_game_start(); s.toolkit.on_game_start()
            s.g.trade_manager.trade_init(s:npc("red_greh_trader"), "original")
            local path = s.path
            s.flags.sim_default_greh_mechanic_upgrade_tier_2 = true
            local tier = s.g.xr_conditions.toolkit_task_done(s.g.db.actor, s:npc("red_greh_tech"), {2})
            s.flags.red_greh_tech_upgrade_tier_1 = true
            s.toolkit.on_game_start(); s.callbacks.actor_on_update()
            local pre = s:eval_task("precondition", input.task)
            local cond = s:eval_task("condlist_0", input.task) or ""
            s:eval_task("on_complete", input.task)
            return table.concat({path, tostring(tier), tostring(#s.writes), pre, cond,
                table.concat(s.effects, ","), tostring(s.flags.sim_default_greh_medic_drugkit_done)}, "|")
        end
        assert(probe(sources) == probe(sources.baseline))
    end)
end

return passed
