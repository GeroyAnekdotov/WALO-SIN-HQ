local passed = 0
local function test(name, fn) fn(); passed = passed + 1; print("SCENARIO PASS: " .. name) end
local function near(a, b) assert(math.abs(a-b) < 0.00001, tostring(a).." ~= "..tostring(b)) end
local function module(source, env)
    local f, e = loadstring(source); assert(f, e); setfenv(f, env)(); return env
end
local function world(native_route)
    local s = {mode = true, story = false, new_game = false, level = "l10_red_forest",
        flags = {story_mode_disabled = true}, callbacks = {}, logs = {}, objects = {},
        dao_calls = 0, beh_calls = 0, seen_vertex = nil, native_created = 0, vertex = 42, clock = 1000}
    local g = setmetatable({}, {__index = _G})
    local function env() return setmetatable({}, {__index = g}) end
    g.vector = function()
        return {set = function(self, x,y,z)
                if type(x)=="table" then self.x,self.y,self.z=x.x,x.y,x.z else self.x,self.y,self.z=x,y,z end
                return self
            end,
            getH = function(self) return math.atan2(-self.x,self.z) end,
            sub = function(self,p) self.x,self.y,self.z=self.x-p.x,self.y-p.y,self.z-p.z; return self end,
            distance_to = function(self,p) return math.sqrt((self.x-p.x)^2+(self.y-p.y)^2+(self.z-p.z)^2) end}
    end
    function s:vec(x,y,z) return g.vector():set(x,y,z) end
    g.printf = function(fmt, ...) s.logs[#s.logs+1] = string.format(fmt, ...) end
    g.IsWarfare = function() return s.mode end
    g.IsStoryMode = function() return s.new_game and s.story or not s.flags.story_mode_disabled end
    g.has_alife_info = function(key) return s.flags[key] end
    g.ini_sys = {section_exist = function() return s.redone end,
        r_string_ex = function() return "katacomb_smart_terrain" end}
    g.axr_main = {config = {r_value = function(_,_,key)
        if key == "new_game_faction" then return s.new_game and "greh" or nil end
        if key == "new_game_story_mode" then return s.story and true or nil end
    end}}
    g.level = {name = function() return s.level end}
    g.db = {actor = {}, storage = {}}
    g.load_var = function(npc,key,default)
        local p = g.db.storage[npc:id()].pstor
        return p and p[key] or default
    end
    g.save_var = function(npc,key,value)
        local st = g.db.storage[npc:id()]; st.pstor=st.pstor or {}; st.pstor[key]=value
    end
    g.xr_conditions = {}
    g.RegisterScriptCallback = function(name, fn)
        s.callbacks[name] = s.callbacks[name] or {}; s.callbacks[name][fn] = true
    end
    function s:first() for fn in pairs(self.callbacks.actor_on_first_update or {}) do fn() end end
    g.alife_object = function(id) return s.objects[id] end
    g.IsAnomaly = function(_, clsid) return clsid == "anomaly" end
    g.alife_create = function() error("service/guard must not create NPCs or props") end
    g.alife_release = function() error("service/guard must not release objects") end
    g.alife_record = function() error("service/guard must not change object registration") end
    s.smart = {id = 777, owning_faction = "greh", m_game_vertex_id = 100}
    g.SIMBOARD = {smarts_by_names = {red_smart_terrain_3_2 = s.smart}}
    s.dao_native = function(...)
        s.dao_calls = s.dao_calls + 1; s.dao_args = {...}
        return 456, "native-object", nil, "tail"
    end
    g.drx_da_main = {drx_da_spawn_anomaly = s.dao_native, updated_anomaly_levels = {}}
    g.game_graph = function() return {vertex = function(_, id)
        return {level_id = function() return id == 100 and 1 or 2 end}
    end} end
    g.alife = function() return {level_name = function(_, id) return id == 1 and "l10_red_forest" or "jupiter" end} end
    g.state_lib = {states = {walking = {movement = 1}, sitting = {movement = 0}}}
    g.move = {stand = 0}
    s.beh_native = function(self, ...)
        s.beh_calls = s.beh_calls + 1; s.seen_vertex = self.st.desired_target.level_vertex_id
        if s.beh_error then error("native beh failure") end
        return "native", nil, "tail"
    end
    g.axr_beh = {action_beh = {beh_path = s.beh_native,
        get_current_waypoint = function(self) return self.st.desired_target end}}
    if native_route then
        assert(sources.beh_route, "native input is required")
        g.str_explode=function(str,sep) local t={} for v in str:gmatch("[^"..sep.."]+") do t[#t+1]=v end return t end
        g.trim=function(str) return str and str:match("^%s*(.-)%s*$") end
        g.time_global=function() return s.clock end
        g.empty_table=function(t) t=t or {}; for k in pairs(t) do t[k]=nil end return t end
        g.get_story_object=function() end
        g.xr_logic={pick_section_from_condlist=function(_,_,value) return value end}
        local logic_env=setmetatable({
            IsStalker=function() return false end,
            get_customdata_or_ini_file=function() return {}, "saved-job" end,
            configure_schemes=function(_,ini) return ini end,
            determine_section_to_activate=function() return "beh@walo_sin_hq_medic" end,
            activate_by_section=function() end,
        },{__index=g})
        module(sources.logic_initialize,logic_env)
        g.xr_logic.initialize_obj=logic_env.initialize_obj
        g.clsid={smart_terrain="smart"}; g.db.offline_objects={}; g.db.spawned_vertex_by_id={}
        s.smart.clsid=function() return "smart" end; s.smart.npc_info={}
        s.smart.setup_logic=function(_,npc)
            s.smart_restores=(s.smart_restores or 0)+1
            local st=g.db.storage[npc:id()]
            st.active_section=st.test_restored_section or "beh@walo_sin_hq_medic"
        end
        local sim=g.alife(); sim.object=function(_,id) if id==777 then return s.smart end end
        g.alife=function() return sim end
        local smart_env=setmetatable({}, {__index=g})
        module(sources.smart_initialize,smart_env)
        g.smart_terrain={setup_gulag_and_logic_on_spawn=smart_env.setup_gulag_and_logic_on_spawn}
        g.game_object={level_path=1}; g.db.used_level_vertex_ids={}
        g.level.vertex_id=function(pos)
            if pos.x==-156.24475097656 then return 5182 end
            if pos.x==-152.677971 then return 222 end -- unchanged barman waypoint
            assert(pos.x==-156.97091674805); return 123
        end
        g.level.vertex_position=function(id) assert(id==5182 or id==123); return s:vec(-156,2.18,-34) end
        g.utils_obj={send_to_nearest_accessible_vertex=function(npc,id)
            -- Model the real utility's accessible/nearest fallback separately.
            s.destination=npc:accessible(id) and id or 5181
            return s.destination
        end}
        g.state_mgr={get_state=function() return s.animation end,
            set_state=function(npc,name,_,_,_,animation)
                if s.animation==name then return end -- native identical-state early return
                s.animation=name; s.animation_data=animation
                g.db.storage[npc:id()].state_mgr.target_state=name
            end}
        g.action_base={finalize=function() end}
        module(sources.beh_route,setmetatable({action_beh=g.axr_beh.action_beh},{__index=g}))
        g.axr_beh.action_beh.set_state=function() s.animation="patrol" end
    end
    g.zzzzzz_walo_sin_hq_core = module(sources.core, env())
    g.zzzzzz_walo_sin_hq_interior_layout = module(sources.layout, env())
    s.guard = module(sources.guard, env()); s.guard.on_game_start()
    s.services = module(sources.services, env()); s.services.on_game_start()
    s.g = g
    function s:spawn(x,y,z,gvid)
        return self.g.drx_da_main.drx_da_spawn_anomaly("zone_mine_gravitational_weak", self:vec(x,y,z), 123, gvid or 100, self.file)
    end
    function s:npc(role, section)
        local id = role == "medic" and 31 or 32
        local server = {id = id, m_smart_terrain_id = 777, position = self:vec(-150,2,-30),
            section_name = function() return section or "sim_default_greh_"..role end,
            name = function() return (section or "sim_default_greh_"..role)..id end}
        self.objects[id] = server
        if self.smart.npc_info then
            self.smart.npc_info[id]={se_obj=server,job={section="logic@walo_sin_hq_"..role},begin_job=true}
        end
        local npc = {id = function() return id end, alive = function() return not s.dead end,
            best_enemy = function() return s.enemy end, is_talking = function() return s.talking end,
            level_vertex_id = function() return s.vertex end,
            position = function() return s:vec(server.position.x,server.position.y,server.position.z) end,
            has_info = function() return false end, accessible = function() return not s.inaccessible end,
            animation_count = function() return s.queued_animations or 0 end,
            set_path_type = function() end, set_desired_direction = function() end,
            set_npc_position = function() error("no teleport") end}
        local st = {active_section = "beh@walo_sin_hq_"..role,
            pstor = {walo_sin_hq_medic_bypass_v1 = true},
            state_mgr = {target_state = "sitting", animation_direction_applied = true,
                animation = {set_state=function(_,name,fast)
                    assert(name==nil and fast==true)
                    s.animation_resets=(s.animation_resets or 0)+1
                end}}}
        self.g.db.storage[id] = st
        return server, npc, setmetatable({object = npc, st = {path_index=2, desired_target = {index=2, level_vertex_id = 123,
            animpoint = self:vec(-156.770994,2.180062,-36.316586), delay_animation = "animpoint_sit_normal"}}},
            {__index=self.g.axr_beh.action_beh}), st
    end
    return s
end

for _, new_game in ipairs({false, true}) do
    for _, mode in ipairs({false, true}) do
        for _, story in ipairs({false, true}) do
            test(string.format("polish gates new=%s Warfare=%s Story=%s", tostring(new_game), tostring(mode), tostring(story)), function()
                local s=world(); s.new_game,s.mode,s.story=new_game,mode,story
                s.flags.story_mode_disabled = not story
                if new_game then s.flags.story_mode_disabled=nil end
                local active = mode and not story
                local obj=s:npc("medic")
                assert(s.services.suitable(nil,obj,{"medic"}) == active)
                s:spawn(-156,2,-30); assert(s.dao_calls == (active and 0 or 1))
            end)
        end
    end
end

test("outside HQ and other levels preserve exact DAO returns and arguments", function()
    local s=world(); s.file={}
    for _,p in ipairs({{-174,2,-30},{-143,2,-30},{-156,-0.01,-30},{-156,6.01,-30},{-156,2,-46.01},{-156,2,-14.99}}) do
        local a,b,c,d=s:spawn(unpack(p)); assert(a==456 and b=="native-object" and c==nil and d=="tail")
        assert(s.dao_args[5] == s.file)
    end
    s.level="jupiter"; s:spawn(-156,2,-30); assert(s.dao_calls==7)
    s.level="l10_red_forest"; s:spawn(-156,2,-30,200); assert(s.dao_calls==8)
end)

test("all measured and stock service/camp points are protected, including raised mattress", function()
    local s=world(); local points={
        {-147.525,2.178,-31.615},{-153.384,2.187,-27.620}, -- named services, untouched
        {-156.192,2.179,-26.436},{-156.771,2.180,-36.317},{-152.767,2.200,-20.536},
        {-161.088,3.116,-28.994},{-170.259,2.286,-40.518},{-166.717,2.223,-43.166},
        {-148.797,2.511,-27.562},{-153.090,2.177,-40.218}, -- stock camp/guard
    }
    for _,p in ipairs(points) do assert(s:spawn(unpack(p))==nil) end
    assert(s.dao_calls==0)
end)

test("saved DAO objects and bookkeeping are inspected without cleanup", function()
    local s=world(); local anomalies={101,102}
    local data={anomalies=anomalies, time=17, anomalies_by_smart={mine={[101]=true}}}
    s.g.drx_da_main.updated_anomaly_levels.l10_red_forest=data
    s.objects[101]={position=s:vec(-156,2,-30), m_game_vertex_id=100, clsid=function() return "anomaly" end}
    s.objects[102]={position=s:vec(-156,12,-30), m_game_vertex_id=100, clsid=function() return "anomaly" end}
    s:first(); s:first()
    assert(data.anomalies==anomalies and #anomalies==2 and data.time==17 and data.anomalies_by_smart.mine[101])
    assert(s.objects[101] and s.dao_calls==0)
end)

test("stale DAO IDs do not identify another class or another level as a mine anomaly", function()
    local s=world()
    s.g.drx_da_main.updated_anomaly_levels.l10_red_forest={anomalies={101,102}}
    s.objects[101]={position=s:vec(-156,2,-30), m_game_vertex_id=100, clsid=function() return "stalker" end}
    s.objects[102]={position=s:vec(-156,2,-30), m_game_vertex_id=200, clsid=function() return "anomaly" end}
    s:first()
    for _,line in ipairs(s.logs) do assert(not line:find("already exist",1,true)) end
end)

test("repeated startup and a later DAO wrapper never build a recursive chain", function()
    local s=world(); local once=s.g.drx_da_main.drx_da_spawn_anomaly
    local later=function(...) return once(...) end; s.g.drx_da_main.drx_da_spawn_anomaly=later
    for _=1,3 do s.guard.on_game_start(); s:first() end
    assert(s.g.drx_da_main.drx_da_spawn_anomaly==later)
    s:spawn(-156,2,-30); s:spawn(0,2,0); assert(s.dao_calls==1)
end)

test("ReDone North exclusion and missing DAO stay inert", function()
    local s=world(); s.redone=true; s:spawn(-156,2,-30); assert(s.dao_calls==1)
    s.g.drx_da_main=nil; s.guard.on_game_start(); s:first()
end)

test("service jobs accept exact generated roles on this greh-owned smart only", function()
    local s=world(); local server,client=s:npc("barman")
    assert(s.services.suitable(nil,server,{"barman"}) and s.services.suitable(nil,client,{"barman"}))
    assert(not s.services.suitable(nil,server,{"medic"}))
    server.m_smart_terrain_id=999; assert(not s.services.suitable(nil,server,{"barman"})); server.m_smart_terrain_id=777
    s.smart.owning_faction="isg"; assert(not s.services.suitable(nil,server,{"barman"})); s.smart.owning_faction="greh"
    for _,name in ipairs({"red_greh_trader","red_greh_tech","sim_default_isg_medic","greh_story_medic"}) do
        local obj=s:npc("medic",name); assert(not s.services.suitable(nil,obj,{"medic"}))
    end
end)

test("medic arrival keeps native results and restores the original graph target", function()
    local s=world(); local server,npc,self,st=s:npc("medic")
    server.position=s:vec(-157.270801,2.180062,-36.302680)
    local a,b,c=s.g.axr_beh.action_beh.beh_path(self)
    assert(a=="native" and b==nil and c=="tail" and s.seen_vertex==42)
    assert(self.st.desired_target.level_vertex_id==123 and st.state_mgr.animation_direction_applied)
    s.beh_error=true; assert(not pcall(s.g.axr_beh.action_beh.beh_path,self))
    assert(self.st.desired_target.level_vertex_id==123)
end)

test("seated helper delegates outside its exact medic job, in combat, dialogue and Story", function()
    for _,reason in ipairs({"barman","other-job","enemy","talking","dead","story","captured"}) do
        local s=world(); local server,npc,self,st=s:npc(reason=="barman" and "barman" or "medic")
        server.position=s:vec(-157.270801,2.180062,-36.302680)
        if reason=="other-job" then st.active_section="beh@some_other_job" end
        if reason=="enemy" then s.enemy={} end
        if reason=="talking" then s.talking=true end
        if reason=="dead" then s.dead=true end
        if reason=="story" then s.story=true; s.flags.story_mode_disabled=false end
        if reason=="captured" then s.smart.owning_faction="isg" end
        s.g.axr_beh.action_beh.beh_path(self); assert(s.seen_vertex==123)
        assert(st.state_mgr.animation_direction_applied)
    end
end)

test("only an own medic walking back can rearm the native sit animation", function()
    local s=world(); local server,npc,self,st=s:npc("medic")
    server.position=s:vec(-156,2.18,-36); st.state_mgr.target_state="walking"
    s.g.axr_beh.action_beh.beh_path(self); assert(st.state_mgr.animation_direction_applied==nil and s.seen_vertex==123)
    st.state_mgr.animation_direction_applied=true; st.state_mgr.target_state="sitting"
    s.g.axr_beh.action_beh.beh_path(self); assert(st.state_mgr.animation_direction_applied)
    s.g.state_lib.states.unknown={}; st.state_mgr.target_state="unknown"
    s.g.axr_beh.action_beh.beh_path(self); assert(st.state_mgr.animation_direction_applied)
end)

test("repeated load preserves earlier and later native beh wrappers", function()
    local s=world(); local once=s.g.axr_beh.action_beh.beh_path
    local later=function(...) return once(...) end; s.g.axr_beh.action_beh.beh_path=later
    for _=1,3 do s.services.on_game_start(); s:first() end
    assert(s.g.axr_beh.action_beh.beh_path==later)
    local _,_,self=s:npc("barman"); s.g.axr_beh.action_beh.beh_path(self); assert(s.beh_calls==1)
end)

test("seat arrival must never skip an intermediate walking waypoint", function()
    local s=world(); local server,npc,self,st=s:npc("medic")
    server.position=s:vec(-157.270801,2.180062,-36.302680)
    self.st.desired_target.animpoint=nil; self.st.desired_target.delay_animation="guard"
    s.g.axr_beh.action_beh.beh_path(self)
    assert(s.seen_vertex==123 and st.state_mgr.animation_direction_applied)
end)

test("native xr_logic parser evaluates the new job predicates", function()
    local s=world(); local g=s.g
    string.trim=function(str) return str:match("^%s*(.-)%s*$") end
    g.AC_ID=0
    g.str_explode=function(str,sep) local t={} for value in string.gmatch(str,"[^"..sep.."]+") do t[#t+1]=value end return t end
    g.aborts={}; g.abort=function(msg) error(msg) end; g.log1=function() end; g.callstack=function() end
    local logic=module(sources.logic,setmetatable({}, {__index=g}))
    for _,role in ipairs({"medic","barman"}) do
        local obj=s:npc(role); local value=sources.jobs["logic@walo_sin_hq_"..role].suitable
        local cond=logic.parse_condlist(nil,"job","suitable",value)
        assert(logic.pick_section_from_condlist(g.db.actor,obj,cond)=="true")
        s.flags.story_mode_disabled=false; s.story=true
        assert(logic.pick_section_from_condlist(g.db.actor,obj,cond)~="true")
        s.flags.story_mode_disabled=true; s.story=false
    end
end)

test("job waypoints align with the unchanged chair and bar, with native trade settings", function()
    local s=world(); local plan=s.g.zzzzzz_walo_sin_hq_interior_layout
    local poses=plan.build(function(_,y) return y end); local chair,left,right
    for _,p in ipairs(poses) do if p.key=="medic_chair" then chair=p elseif p.key=="barrel_left" then left=p elseif p.key=="barrel_right" then right=p end end
    local line=sources.jobs["beh@walo_sin_hq_medic"].pt2
    local anim=line:match("animpoint:(.*)"); local t={} for n in anim:gmatch("[^,]+") do t[#t+1]=tonumber(n) end
    near(chair.pos[1],t[1]+0.5*t[4]); near(chair.pos[2],t[2]); near(chair.pos[3],t[3]+0.5*t[6])
    near(chair.heading,s.g.vector():set(t[4],0,t[6]):getH()%(2*math.pi))
    local bx,by,bz=sources.jobs["beh@walo_sin_hq_barman"].pt1:match("pos:([^,]+),([^,]+),([^ ]+)")
    local dx,dz=tonumber(bx)-(left.pos[1]+right.pos[1])/2,tonumber(bz)-(left.pos[3]+right.pos[3])/2
    near(math.sqrt(dx*dx+dz*dz),0.95)
    local dir=plan.areas.bar.dir
    assert(dx*dir[1]+dz*dir[3]<0) -- opposite side of the previous job
    local lx,ly,lz=sources.jobs["beh@walo_sin_hq_barman"].pt1:match("look:([^,]+),([^,]+),([^ ]+)")
    near(tonumber(lx),(left.pos[1]+right.pos[1])/2); near(tonumber(lz),(left.pos[3]+right.pos[3])/2)
    for _,role in ipairs({"medic","barman"}) do
        local logic=sources.jobs["logic@walo_sin_hq_"..role]
        assert(logic.level_spot==role and logic.trade=="items\\trade\\trade_generic_"..role..".ltx")
    end
end)

test("medic destination is outside the table; chair and body clearance remain unverified", function()
    local s=world(); local plan=s.g.zzzzzz_walo_sin_hq_interior_layout
    local poses=plan.build(function(_,y) return y end); local table_piece,chair
    for _,p in ipairs(poses) do if p.key=="medic_table" then table_piece=p elseif p.key=="medic_chair" then chair=p end end
    local x,y,z=sources.jobs["beh@walo_sin_hq_medic"].pt2:match("pos:([^,]+),([^,]+),([^ ]+)")
    x,y,z=tonumber(x),tonumber(y),tonumber(z)
    assert(x==-156.97091674805 and y==2.1770622730255 and z==-36.311023712158)
    local function within_table(px,pz)
        local dx,dz=px-table_piece.pos[1],pz-table_piece.pos[3]; local h=table_piece.heading
        local lx,lz=dx*math.cos(h)+dz*math.sin(h),-dx*math.sin(h)+dz*math.cos(h)
        -- Exact render bounds of the verified WALO awr_stol_9a_mini model.
        return lx>=-0.7614731788635254 and lx<=0.7614730596542358
            and lz>=-0.32682329416275024 and lz<=0.32682329416275024
    end
    assert(within_table(-156.471110,-36.324930)) -- previous target was inside
    assert(not within_table(x,z))
    assert(s:vec(x,y,z):distance_to(s:vec(unpack(chair.pos)))<0.8)
end)

if sources.beh_waypoint then
    test("audited native beh parser reads the corrected service waypoint and sit fields", function()
        local s=world(); local g=s.g; local server,npc,self,st=s:npc("medic")
        g.str_explode=function(str,sep) local t={} for v in str:gmatch("[^"..sep.."]+") do t[#t+1]=v end return t end
        g.trim=function(str) return str:match("^%s*(.-)%s*$") end
        npc.has_info=function() return false end
        g.level.vertex_id=function(pos) assert(pos.x==-156.97091674805); return 123 end
        self.st.path_index=2; self.st.desired_target=nil
        st.ini={r_string_ex=function(_,section,key) return sources.jobs[section][key] end}
        local parser={}
        local env=setmetatable({action_beh=parser},{__index=g})
        module(sources.beh_waypoint,env)
        local p=parser.get_current_waypoint(self)
        assert(p.level_vertex_id==123 and p.delay==1000000000 and p.delay_animation=="animpoint_sit_normal")
        assert(p.animpoint and p.animpoint_dir and p.active_section=="beh@walo_sin_hq_medic")
        self.st.desired_target=p; server.position=s:vec(-157.270801,2.180062,-36.302680)
        g.axr_beh.action_beh.beh_path(self); assert(s.seen_vertex==42 and p.level_vertex_id==123)
    end)
end

if sources.beh_route then
    local key="walo_sin_hq_medic_bypass_v1"
    local function route(index,visited,role)
        local s=world(true)
        local server,npc,action,st=s:npc(role or "medic")
        st.pstor={[key]=visited,path_index=index}
        st.ini={r_string_ex=function(_,section,name) return sources.jobs[section][name] end}
        action.st={path_index=index,goto_target="waypoint",path_end="loop",signals={}}
        return s,server,npc,action,st
    end

    test("native ordered route selects the exact bypass before the unchanged sit target",function()
        local s,server,npc,a,st=route(1,false)
        assert(a:set_desired_target()); local p=a.st.desired_target
        assert(p.index==1 and p.level_vertex_id==5182 and p.delay==500 and p.delay_animation=="guard")
        assert(p.position.x==-156.24475097656 and p.position.y==2.1791143417358 and p.position.z==-34.401062011719)
        assert(not p.animpoint)
        a:beh_path(); assert(s.destination==5182 and a.st.path_index==1 and not st.pstor[key])
        s.vertex=5182; server.position=s:vec(p.position.x,p.position.y,p.position.z)
        a:beh_path(); assert(st.pstor[key] and a.st.path_index==1 and s.animation=="guard")
        s.clock=s.clock+499; a:beh_path(); assert(a.st.path_index==1)
        s.clock=s.clock+2; a:beh_path(); assert(a.st.path_index==2 and st.pstor.path_index==2)
        assert(a:set_desired_target()); p=a.st.desired_target
        assert(p.index==2 and p.level_vertex_id==123 and p.position.x==-156.97091674805)
        a:beh_path(); assert(s.destination==123 and s.animation=="patrol")
        server.position=s:vec(-157.270801,2.180062,-36.302680); s.vertex=5103
        a:beh_path(); assert(s.animation=="animpoint_sit_normal" and p.level_vertex_id==123)
        near(s.animation_data.animation_position.x,-156.770994)
        near(s.animation_data.animation_direction.x,-0.999613179)
        assert(a.st.path_index==2 and not a.st.path_reverse)
    end)

    test("native nearest-accessible fallback and proximity never count as visiting 5182",function()
        local s,server,npc,a,st=route(1,false)
        a:set_desired_target(); s.inaccessible=true; a:beh_path()
        assert(s.destination==5181 and a.st.desired_target.level_vertex_id==5182)
        s.vertex=5181; server.position=s:vec(-156.24475097656,2.1791143417358,-34.401062011719)
        s.clock=s.clock+100000; a:beh_path()
        assert(a.st.path_index==1 and not st.pstor[key] and not a.st.wait_delay)
        -- Even the chair's arrival radius must not shorten a walking waypoint.
        server.position=s:vec(-157.270801,2.180062,-36.302680); a:beh_path()
        assert(a.st.path_index==1 and not st.pstor[key] and s.destination==5181)
    end)

    test("old or inherited saved indices cannot select the chair without bypass evidence",function()
        for _,index in ipairs({0,2,3,50}) do
            local s,server,npc,a,st=route(index,false)
            a.st.path_reverse=true; a.st.wait_delay=999999; a.st.am_i_reached=true
            a:set_desired_target()
            assert(a.st.path_index==1 and a.st.desired_target.level_vertex_id==5182)
            assert(st.pstor.path_index==1 and not a.st.path_reverse and not a.st.wait_delay and not a.st.am_i_reached)
        end
        local s,server,npc,a,st=route(1,false)
        a.st.path_reverse=true; a.st.desired_target={index=1,active_section=st.active_section,
            animpoint=s:vec(0,0,0),level_vertex_id=123}
        local p=a:get_current_waypoint()
        assert(p.level_vertex_id==5182 and not p.animpoint and not a.st.path_reverse)
    end)

    test("native path index and per-NPC bypass evidence survive mocked save/load",function()
        for _,case in ipairs({{1,false,1},{2,false,1},{1,true,1},{2,true,2}}) do
            local s,server,npc,a,st=route(case[1],case[2])
            a:set_desired_target(); assert(a.st.path_index==case[3])
            local copy={path_index=st.pstor.path_index,[key]=st.pstor[key]}
            local next_world,_,_,b,loaded=route(copy.path_index,copy[key])
            b:set_desired_target(); assert(b.st.path_index==case[3])
        end
        -- Reusing an object id in another game cannot inherit module-local proof.
        local s,_,_,a=route(2,true); a:set_desired_target(); assert(a.st.path_index==2)
        local fresh,_,_,b=route(2,false); b:set_desired_target(); assert(b.st.path_index==1)
    end)

    test("native finalization and reassignment retain the native forward route",function()
        local s,server,npc,a,st=route(2,true)
        a:set_desired_target(); a:finalize(); assert(st.pstor.path_index==1 and st.pstor[key])
        -- Native initialization reads that saved index; no recurring forced movement.
        a.st={path_index=st.pstor.path_index,goto_target="waypoint",path_end="loop",signals={}}
        a:set_desired_target(); assert(a.st.desired_target.level_vertex_id==5182)
    end)

    test("reload at the chair resumes the completed medic job without revisiting the bypass",function()
        local s,server,npc,a,st=route(2,true)
        server.position=s:vec(-157.270801,2.180062,-36.302680); s.vertex=5103
        a:set_desired_target(); a:beh_path()
        assert(s.animation=="animpoint_sit_normal")
        a:finalize(); assert(st.pstor.path_index==1)
        -- Native initialization reads path_index=1; the new manager is idle.
        a.st={path_index=st.pstor.path_index,goto_target="waypoint",path_end="loop",signals={}}
        s.animation="idle"; st.state_mgr.target_state="idle"; st.state_mgr.animation_direction_applied=nil
        a:set_desired_target()
        assert(a.st.path_index==2 and a.st.desired_target.index==2 and st.pstor.path_index==2)
        s.destination=nil; a:beh_path()
        assert(s.animation=="animpoint_sit_normal" and not s.destination)
        assert(a.st.desired_target.level_vertex_id==123 and s.vertex==5103)
        for _=1,3 do s.services.on_game_start(); s:first(); a:set_desired_target(); a:beh_path() end
        assert(a.st.path_index==2 and not s.destination)
        local count=0; for _ in pairs(s.callbacks.actor_on_first_update) do count=count+1 end
        assert(count==2) -- one existing DAO callback and one service callback
    end)

    test("restoring the seat requires bypass evidence, calm own medic and current Red Forest",function()
        for _,reason in ipairs({"unvisited","away","combat","dialogue","dead","story","other-level","barman"}) do
            local s,server,npc,a,st=route(1,reason~="unvisited",reason=="barman" and "barman" or "medic")
            server.position=s:vec(-157.270801,2.180062,-36.302680)
            if reason=="away" then server.position=s:vec(-156,2,-30) end
            if reason=="combat" then s.enemy={} end
            if reason=="dialogue" then s.talking=true end
            if reason=="dead" then s.dead=true end
            if reason=="story" then s.flags.story_mode_disabled=false end
            if reason=="other-level" then s.level="jupiter" end
            a:set_desired_target(); assert(a.st.path_index==1)
        end
    end)

    test("native saved job restores sitting even when bypass pstor is absent and ownership is late",function()
        local s,server,npc,a,st=route(1,false)
        server.position=s:vec(-157.4372,2.1783,-36.29145); s.vertex=5102
        for _=1,2 do
            st.pstor={} -- reproduce the actual post-load diagnostic, not an assumed retained flag
            st.loaded_section_logic="logic@walo_sin_hq_medic"
            st.loaded_active_section="beh@walo_sin_hq_medic"
            s.smart.owning_faction="isg"
            s.g.smart_terrain.setup_gulag_and_logic_on_spawn(npc,st,server,0,true)
            -- The real assigned-smart branch returns without initialize_obj.
            assert(st.loaded_active_section=="beh@walo_sin_hq_medic" and s.smart_restores)
            assert(st._walo_sin_saved_seat)
            a.st={path_index=1,goto_target="waypoint",path_end="loop",signals={}}
            a:set_desired_target(); assert(a.st.path_index==1 and not st.pstor[key])
            s.smart.owning_faction="greh"
            a:set_desired_target()
            assert(a.st.path_index==2 and st.pstor[key] and not st._walo_sin_saved_seat)
            s.animation="idle"; s.destination=nil
            a:beh_path(); assert(s.animation=="animpoint_sit_normal" and not s.destination)
        end
    end)

    test("saved-seat evidence excludes new spawn, level-entry centre, other jobs and other NPCs",function()
        for _,reason in ipairs({"fresh","away","other-job","other-level","other-npc"}) do
            local s,server,npc,a,st=route(1,false)
            server.position=s:vec(-157.4372,2.1783,-36.29145)
            st.loaded_section_logic="logic@walo_sin_hq_medic"
            st.loaded_active_section="beh@walo_sin_hq_medic"
            if reason=="away" then server.position=s:vec(-150,2,-30) end
            if reason=="other-job" then st.test_restored_section="beh@walo_sin_hq_barman" end
            if reason=="other-level" then s.level="jupiter" end
            if reason=="other-npc" then server.section_name=function() return "sim_default_isg_medic" end end
            s.g.smart_terrain.setup_gulag_and_logic_on_spawn(npc,st,server,0,reason~="fresh")
            if reason~="other-job" then assert(not st._walo_sin_saved_seat) end
            a:set_desired_target(); assert(a.st.path_index==1 and not st.pstor[key])
        end
    end)

    test("saved-job wrapper retains later handlers across repeated startup",function()
        local s,server,npc,a,st=route(1,false)
        local previous=s.g.smart_terrain.setup_gulag_and_logic_on_spawn; local calls=0
        local later=function(...) calls=calls+1; return previous(...) end
        s.g.smart_terrain.setup_gulag_and_logic_on_spawn=later
        for _=1,3 do s.services.on_game_start(); s:first() end
        assert(s.g.smart_terrain.setup_gulag_and_logic_on_spawn==later)
        st.loaded_section_logic="logic@walo_sin_hq_medic"; st.loaded_active_section="beh@walo_sin_hq_medic"
        s.g.smart_terrain.setup_gulag_and_logic_on_spawn(npc,st,server,0,true); assert(calls==1)
    end)

    test("local reload rearms a cached sit request with an empty animation queue exactly once",function()
        local s,server,npc,a,st=route(2,true)
        server.position=s:vec(-157.270801,2.180062,-36.302680); s.vertex=5103
        a:set_desired_target()
        s.animation="animpoint_sit_normal"; st.state_mgr.target_state=s.animation
        st.state_mgr.animation_direction_applied=true
        a:beh_path()
        assert(s.animation_resets==1 and s.animation_data and s.animation=="animpoint_sit_normal")
        assert(st.state_mgr.animation_direction_applied==nil and st.state_mgr._walo_sin_seat_checked)
        for _=1,3 do s.services.on_game_start(); s:first(); a:set_desired_target(); a:beh_path() end
        assert(s.animation_resets==1 and not s.destination and a.st.path_index==2)
        -- A newly constructed state manager on another load may be repaired once again.
        st.state_mgr._walo_sin_seat_checked=nil; s.animation_data=nil
        a:beh_path(); assert(s.animation_resets==2 and s.animation_data)
    end)

    test("first arrival and an already queued sitting animation are never reset",function()
        for _,queued in ipairs({0,1}) do
            local s,server,npc,a,st=route(2,true)
            server.position=s:vec(-157.270801,2.180062,-36.302680); s.vertex=5103
            a:set_desired_target(); s.queued_animations=queued
            s.animation=queued==0 and "patrol" or "animpoint_sit_normal"
            st.state_mgr.target_state=s.animation
            a:beh_path(); a:beh_path()
            assert(not s.animation_resets and st.state_mgr._walo_sin_seat_checked)
            assert(s.animation=="animpoint_sit_normal")
        end
    end)

    test("route wrappers delegate exactly outside the SIN medic exclusive job",function()
        for _,reason in ipairs({"barman","other-job","story","captured","other-smart","named","other-faction"}) do
            local s,server,npc,a,st=route(2,false,reason=="barman" and "barman" or "medic")
            if reason=="story" then s.flags.story_mode_disabled=false end
            if reason=="captured" then s.smart.owning_faction="isg" end
            if reason=="other-smart" then server.m_smart_terrain_id=888 end
            if reason=="named" then server.section_name=function() return "red_greh_trader" end end
            if reason=="other-faction" then server.section_name=function() return "sim_default_isg_medic" end end
            if reason=="other-job" then st.active_section="beh@walo_sin_hq_barman" end
            local p=a:get_current_waypoint()
            assert(a.st.path_index==2 and st.pstor.path_index==2 and not st.pstor[key])
            if reason=="barman" or reason=="other-job" then assert(not p.level_vertex_id)
            else assert(p.delay_animation=="animpoint_sit_normal") end
        end
    end)

    test("both route wrappers install once and retain later handlers and error propagation",function()
        local s,server,npc,a,st=route(1,false)
        local cls=s.g.axr_beh.action_beh
        local waypoint,path=cls.get_current_waypoint,cls.beh_path
        local reads=0
        cls.get_current_waypoint=function(...) reads=reads+1; return waypoint(...) end
        cls.beh_path=function(...) return path(...) end
        local later_get,later_path=cls.get_current_waypoint,cls.beh_path
        for _=1,3 do s.services.on_game_start(); s:first() end
        assert(cls.get_current_waypoint==later_get and cls.beh_path==later_path)
        a:set_desired_target(); a:beh_path(); assert(reads==1 and s.destination==5182)
        st.ini.r_string_ex=function() error("native waypoint error") end
        assert(not pcall(a.get_current_waypoint,a))
    end)
end

if sources.dao_caller then
    test("audited DAO caller/creator skip creation cleanly but still spawn outside HQ", function()
        local s=world(); local g=s.g; local dao=g.drx_da_main
        local env=setmetatable(dao,{__index=g})
        g.level_vertex_id=function() return 123 end
        g.random=function(a,b) return a end
        g.anomaly_radii={}; g.CreateTimeEvent=function() error("native abort not expected") end
        g.utils_stpk={get_anom_zone_data=function() return {shapes={}} end,set_anom_zone_data=function() end}
        local sim=g.alife(); sim.create=function(_,typ,pos,lvid,gvid) s.native_created=s.native_created+1; return {id=500} end
        g.alife=function() return sim end
        s.file={r_float_ex=function(_,section,key) return key=="min_radius" and 2 or 3 end}
        module(sources.dao_caller,env); module(sources.dao_creator,env)
        -- A genuinely new table represents module reloading; install once on it.
        g.drx_da_main=setmetatable({}, {__index=dao})
        g.drx_da_main.drx_da_spawn_anomaly=dao.drx_da_spawn_anomaly
        s.guard.on_game_start()
        dao.drx_da_spawn_anomaly=g.drx_da_main.drx_da_spawn_anomaly
        dao.drx_da_generate_position=function() return s:vec(-156,2,-30) end
        assert(not dao.drx_da_spawn_anomaly_on_smart(s.file,"red_smart_terrain_3_2","zone_mine_gravitational_weak","l10_red_forest"))
        assert(s.native_created==0)
        dao.drx_da_generate_position=function() return s:vec(-190,2,-30) end
        assert(dao.drx_da_spawn_anomaly_on_smart(s.file,"red_smart_terrain_3_2","zone_mine_gravitational_weak","l10_red_forest")==500)
        assert(s.native_created==1)
    end)
end
return passed
