local passed = 0
local function test(name, body)
    body(); passed = passed + 1; print("SCENARIO PASS: " .. name)
end
local function equal(a, b) assert(math.abs(a - b) < 0.00001, tostring(a) .. " ~= " .. tostring(b)) end
local function copy(t)
    if type(t) ~= "table" then return t end
    local r = {}; for k, v in pairs(t) do r[k] = copy(v) end; return r
end
local function module(source, shared)
    local env = setmetatable({}, {__index = shared})
    local fn, err = loadstring(source); assert(fn, err); setfenv(fn, env)(); return env
end
local function world()
    local s = {state = {}, objects = {}, next_id = 1, created = 0, released = 0, now = 20000,
        callbacks = {}, timers = {}, map = {}, mode = true, story = false, new_game = false,
        level = "l10_red_forest", actor_pos = {-155.27287929248, 2.1776688098907, -25.073003768921},
        flags = {story_mode_disabled = true}, ui_calls = 0, native_sleeps = 0, own_sleeps = 0,
        prompts = 0, ray_delta = -0.05}
    local g = setmetatable({}, {__index = _G})
    g.vector = function()
        local v = {}
        function v:set(x, y, z)
            if type(x) == "table" then self.x, self.y, self.z = x.x, x.y, x.z
            else self.x, self.y, self.z = x, y, z end; return self
        end
        function v:distance_to(o) return math.sqrt((self.x-o.x)^2+(self.y-o.y)^2+(self.z-o.z)^2) end
        function v:getH() return math.atan2(-self.x, self.z) end
        return v
    end
    local function vec(p) return g.vector():set(p[1], p[2], p[3]) end
    s.vec = vec
    g.printf = function() end
    g.IsWarfare = function() return s.mode end
    g.IsStoryMode = function() return s.new_game and s.story or not s.flags.story_mode_disabled end
    g.has_alife_info = function(key) return s.flags[key] end
    g.give_info = function(key) s.flags[key] = true end
    g.axr_main = {config = {r_value = function(_, _, key)
        if key == "new_game_faction" then return s.new_game and "greh" or nil end
        if key == "new_game_story_mode" then return s.story and true or nil end
    end}}
    g.ini_sys = {section_exist = function(_, section)
        if section == "kat_greh_trader_squad" then return false end
        return section ~= s.missing_section
    end, r_string_ex = function() return [[dynamics\workshop_room\awr_tiski.ogf]] end}
    g.getFS = function() return {exist = function() return not s.missing_mesh end} end
    local actor = {id = function() return 0 end, position = function() return vec(s.actor_pos) end,
        level_vertex_id = function() return 321 end}
    g.db = {actor = actor}
    g.alife_storage_manager = {get_state = function() return s.state end}
    g.time_global = function() return s.now end
    g.RegisterScriptCallback = function(name, fn) s.callbacks[name] = fn end
    g.alife_object = function(id) return s.objects[id] end
    g.alife_release = function(obj) s.objects[obj.id] = nil; s.released = s.released + 1 end
    g.alife_create = function(section, pos, lvid, gvid)
        local id = s.next_id; s.next_id = id + 1; s.created = s.created + 1
        local obj = {id = id, data = {custom_data = "", mass = 10}, section_value = section, pos = vec({pos.x,pos.y,pos.z})}
        function obj:section_name() return self.section_value end
        function obj:position() return self.pos end
        function obj:name() return self.section_value .. self.id end
        s.objects[id] = obj; return obj
    end
    g.utils_stpk = {
        get_physic_data = function(obj) return copy(obj.data) end,
        get_space_restrictor_data = function(obj) return copy(obj.data) end,
    }
    local function packet(data, obj)
        if s.fail_packet and obj.id == 1 then error("simulated packet failure") end
        obj.data = copy(data)
    end
    g.utils_stpk.set_physic_data, g.utils_stpk.set_space_restrictor_data = packet, packet
    g.warfare_utils = {nearest_lvid = function(pos)
        if s.off_graph_bed and math.abs(pos.x + 161.08793640137) < 0.1
            and math.abs(pos.z + 28.994010925293) < 0.1 then return nil end
        return 123
    end, smart_on_actor_level = function() return {m_game_vertex_id = 2772} end}
    g.level = {name = function() return s.level end, object_by_id = function(id) return s.objects[id] end,
        map_has_object_spot = function(id) return s.map[id] and 1 or 0 end,
        map_add_object_spot_ser = function(id) s.map[id] = true end}
    g.ray_pick = function()
        return {set_flags = function(_, v) assert(v == 2) end, set_range = function() end,
            set_position = function() end, set_direction = function() end,
            query = function() return not s.no_floor end, get_distance = function() return 0.35 - s.ray_delta end}
    end
    g.ui_workshop = {get_workshop_ui = function(_, mechanic, flags)
        assert(mechanic == nil); for _, value in ipairs(flags) do assert(not value) end
        s.ui_calls = s.ui_calls + 1; return {ShowDialog = function() end}
    end}
    g.get_hud = function() return {} end
    g.actor_effects = {is_animations_on = function() return true end, play_item_fx = function() end}
    g.CreateTimeEvent = function(_, _, _, fn) s.timers[#s.timers + 1] = fn end
    g.ui_sleep_dialog = {sleep_in_zone = function() s.native_sleeps = s.native_sleeps + 1; return "native", "extra" end,
        sleep = function() s.own_sleeps = s.own_sleeps + 1 end}
    g.game = {has_active_tutorial = function() return s.active_tutorial end,
        start_tutorial = function(name) assert(name == "tutorial_sleep"); s.prompts = s.prompts + 1; s.active_tutorial = true end}
    g.zzzzzz_walo_sin_hq_core = module(sources.core, g)
    s.layout = module(sources.layout, g); g.zzzzzz_walo_sin_hq_interior_layout = s.layout
    s.interior = module(sources.interior, g); s.interior.on_game_start()
    function s:tick() self.now = self.now + 2100; self.callbacks.actor_on_update() end
    function s:records() return self.state.walo_sin_hq_interior_v01 end
    function s:vice() return self.objects[self:records().workbench_vice.id] end
    function s:use()
        local server = self:vice()
        self.actor_pos = {server.pos.x, server.pos.y, server.pos.z}
        local client = {id = function() return server.id end, position = function() return server.pos end}
        self.callbacks.physic_object_on_use_callback(client, actor)
    end
    function s:drain() local timers = self.timers; self.timers = {}; for _, f in ipairs(timers) do assert(f()) end end
    s.g = g
    return s
end

for _, new_game in ipairs({false, true}) do
    for _, warfare in ipairs({false, true}) do
        for _, story in ipairs({false, true}) do
            test(string.format("creation mode new=%s Warfare=%s Story=%s", tostring(new_game), tostring(warfare), tostring(story)), function()
                local s = world(); s.new_game, s.mode, s.story = new_game, warfare, story
                s.flags.story_mode_disabled = not story
                if new_game then s.flags.story_mode_disabled = nil end
                s:tick(); assert(s.created == (warfare and not story and 19 or 0))
            end)
        end
    end
end

test("foreign levels never receive SIN objects", function()
    local s = world(); s.level = "jupiter"; s:tick(); assert(s.created == 0 and not s:records())
end)
test("static floor and render pivots determine the ground props", function()
    local s = world(); s:tick()
    local table_obj = s.objects[s:records().medic_table.id]
    equal(table_obj.pos.y, s.layout.areas.medic.pos[2] - 0.05 - 0.0016651214100420475 + 0.003)
    equal(s:vice().pos.y - s.objects[s:records().workbench_table.id].pos.y, 0.85135)
    assert(table_obj.data.mass == 10)
end)
test("bad floor rays are bounded and fall back to the measured area height", function()
    local s = world(); s.ray_delta = -5; s:tick()
    equal(s.objects[s:records().medic_table.id].pos.y, s.layout.areas.medic.pos[2] - 0.0016651214100420475 + 0.003)
end)
test("same-save reload and repeated startup reuse all nineteen IDs", function()
    local s = world(); s:tick(); local first = copy(s:records())
    for _ = 1, 3 do s.interior.on_game_start(); s.callbacks.actor_on_first_update(); s:tick() end
    assert(s.created == 19 and s.released == 0)
    for key, value in pairs(first) do assert(s:records()[key].id == value.id) end
end)
test("partial initialization holds its reserved ID instead of duplicating", function()
    local s = world(); s.fail_packet = true; s:tick(); assert(s.created == 19)
    s.fail_packet = false; s.interior.on_game_start(); s:tick()
    assert(s.created == 19 and not s:records().workbench_table.ready)
end)
test("foreign/reused IDs are neither modified nor released", function()
    local s = world(); s:tick(); local obj = s:vice(); obj.data.custom_data = "[other_mod]\n"
    s.interior.on_game_start(); s:tick(); assert(s.created == 19 and s.released == 0)
    assert(obj.data.custom_data == "[other_mod]\n")
end)
test("pose corrections replace only owned tagged objects after unregister", function()
    local s = world(); s:tick(); s.layout.areas.workbench.pos[1] = s.layout.areas.workbench.pos[1] + 0.1
    s.interior.on_game_start(); s:tick(); assert(s.released == 2 and s.created == 19)
    s:tick(); assert(s.created == 21 and s.released == 2)
end)

test("polishing moves only the existing first-pass table and vice", function()
    local s = world()
    local current = copy(s.layout.areas.workbench)
    s.layout.areas.workbench = {pos = {-155.288016, 2.1290036884807, -24.323157},
        heading = math.atan2(0.020182311534882, 0.9997963309288)}
    s:tick(); local first = copy(s:records())
    s.layout.areas.workbench = current
    s.interior.on_game_start(); s:tick(); assert(s.released == 2 and s.created == 19)
    s:tick(); assert(s.created == 21)
    for key, record in pairs(first) do
        if key ~= "workbench_table" and key ~= "workbench_vice" then assert(s:records()[key].id == record.id) end
    end
    for _ = 1, 3 do s.interior.on_game_start(); s:tick() end
    assert(s.created == 21 and s.released == 2)
end)

test("exact workbench origin retains both tested rotations and the native vice offset", function()
    local s = world(); s.no_floor = true; s:tick()
    local table_obj = s.objects[s:records().workbench_table.id]
    local vice = s:vice()
    assert(table_obj.pos.x == -156.07967 and table_obj.pos.y == 2.1779747009277
        and table_obj.pos.z == -25.93725)
    assert(table_obj.angle.y == 3.1506574156321507)
    equal(vice.pos.x, -156.09188051122872); equal(vice.pos.z, -25.716437026161215)
    assert(vice.angle.y == 1.579102108452564)
end)

test("workbench never reapplies floor, pivot or obsolete facing offsets", function()
    for _,delta in ipairs({-0.3,0.2,4}) do
        local s=world(); s.ray_delta=delta
        s.layout.areas.workbench.dir={1,0,0}; s.layout.areas.workbench.forward=10; s.layout.areas.workbench.right=10
        s:tick(); local p=s.objects[s:records().workbench_table.id].pos
        assert(p.x == -156.07967 and p.y == 2.1779747009277 and p.z == -25.93725)
    end
end)

test("updating earlier workbench poses changes only its pair and keeps exact rotations", function()
    for _,position in ipairs({{-156.19209983700418,2.1290899960064,-26.436256112764415},
            {-156.13198852539,2.1792418956757,-25.346315383911},
            {-156.57952880859,2.1779747009277,-25.925189971924},
            {-156.32960,2.1779747009277,-25.93122}}) do
        local s=world(); local current=copy(s.layout.areas.workbench)
        s.layout.areas.workbench.pos=position
        s:tick(); local first=copy(s:records()); local h1=s:vice().angle.y
        s.layout.areas.workbench=current; s.interior.on_game_start(); s:tick(); s:tick()
        assert(s.created==21 and s.released==2 and s:vice().angle.y==h1)
        for key,r in pairs(first) do
            if key~="workbench_table" and key~="workbench_vice" then assert(s:records()[key].id==r.id) end
        end
    end
end)
test("missing sections/models fail before object creation", function()
    local s = world(); s.missing_mesh = true; s:tick(); assert(s.created == 1) -- invisible marker only
    s = world(); s.missing_section = "walo_sin_hq_workbench"; s:tick(); assert(s.created == 18)
end)
test("private vice opens native crafting UI without fabricated toolkit flags", function()
    local s = world(); s:tick(); assert(not s:vice():name():find("awr"))
    s:use(); s:drain(); assert(s.ui_calls == 1)
    s.story = true; s.flags.story_mode_disabled = false
    s:use(); s:drain(); assert(s.ui_calls == 1)
end)
test("delayed workshop use cannot cross a save boundary", function()
    local s = world(); s:tick(); s:use(); s.callbacks.actor_on_first_update(); s:drain()
    assert(s.ui_calls == 0)
end)
test("workbench follows native use callbacks even without a forwarded sender", function()
    local s = world(); s:tick(); local server = s:vice()
    s.actor_pos = {server.pos.x, server.pos.y, server.pos.z}
    local client = {id = function() return server.id end, position = function() return server.pos end}
    s.callbacks.physic_object_on_use_callback(client, nil); s:drain(); assert(s.ui_calls == 1)
    s.actor_pos = {0, 0, 0}; s.callbacks.physic_object_on_use_callback(client, nil); s:drain()
    assert(s.ui_calls == 1)
end)
test("the existing elevated mattress gets no new visible bed", function()
    local s = world(); s:tick(); local marker = s.objects[s:records().sleep_marker.id]
    assert(marker:section_name() == "space_restrictor" and marker.data.restrictor_type == 3)
    equal(marker.pos.y, 3.116215467453)
    for _, obj in pairs(s.objects) do assert(not obj:section_name():find("bed")) end
end)
test("off-graph mattress marker can use only the nearby actor's graph cell", function()
    local s = world(); s.off_graph_bed = true; s:tick(); assert(s.created == 18)
    s.actor_pos = copy(s.layout.sleep.pos); s:tick(); assert(s.created == 19)
end)
test("sleep uses native dialog only at the active confirmed mattress", function()
    local s = world(); s:tick(); local original_hook = s.g.ui_sleep_dialog.sleep_in_zone
    for _ = 1, 3 do s.interior.on_game_start() end
    assert(s.g.ui_sleep_dialog.sleep_in_zone == original_hook)
    s.actor_pos = copy(s.layout.sleep.pos); s:tick(); assert(s.prompts == 1)
    s.g.ui_sleep_dialog.sleep_in_zone(); assert(s.own_sleeps == 1 and s.flags.sleep_active)
    s.flags.story_mode_disabled = false; s.story = true
    local a, b = s.g.ui_sleep_dialog.sleep_in_zone()
    assert(a == "native" and b == "extra" and s.native_sleeps == 1 and s.own_sleeps == 1)
end)
test("foreign tutorials and foreign sleep locations retain their handlers", function()
    local s = world(); s.active_tutorial = true; s.actor_pos = copy(s.layout.sleep.pos); s:tick()
    assert(s.prompts == 0)
    s.actor_pos = {0, 0, 0}; local a, b = s.g.ui_sleep_dialog.sleep_in_zone()
    assert(a == "native" and b == "extra" and s.native_sleeps == 1)
end)
test("switching to a separate Story save carries no creation/state into it", function()
    local s = world(); s:tick(); s.state = {}; s.objects = {}; s.story = true; s.flags.story_mode_disabled = false
    s.interior.on_game_start(); s.callbacks.actor_on_first_update(); s:tick()
    assert(s.created == 19 and not s:records())
end)
return passed
