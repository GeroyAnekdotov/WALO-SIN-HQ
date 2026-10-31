local passed = 0
local function test(name, fn) fn(); passed=passed+1; print("SCENARIO PASS: "..name) end
local function module(text, env)
    local f,e=loadstring(text); assert(f,e); setfenv(f,env)(); return env
end
local function world(kind, bridge_first)
    local isg, sin = kind~="sin", kind~="unisg"
    local s={new=true,story=false,warfare=true,random=false,pop=2,spawns={},save={},registry={},callbacks={},core_new=0,core_load=0,graph_calls=0}
    local g=setmetatable({}, {__index=_G}); g._G=g
    local noop=function() end
    g.printf=noop; g.IsWarfare=function() return s.warfare end
    g.IsStoryMode=function() return s.story end
    g.has_alife_info=function(key) return key=="story_mode_disabled" and not s.story end
    g.get_actor_true_community=function() return "greh" end
    g.give_info=function() s.native_first=true end
    g.axr_main={config={r_value=function(_,_,key)
        if key=="new_game_faction" then return s.new and "greh" or nil end
        if key=="new_game_story_mode" then return s.story or nil end
    end}}
    g.ini_sys={section_exist=function(_,section)
        if section=="isg_sim_squad_novice" then assert(isg,"SIN queried an UNISG section"); return true end
        return section=="kat_greh_trader_squad" and s.redone or false
    end,r_string_ex=function(_,_,key)
        if key=="faction" then return "greh" end
        if key=="target_smart" then return "katacomb_smart_terrain" end
    end,r_bool_ex=function() return true end}
    g.db={actor={}}
    s.mine={id=10,name=function() return "red_smart_terrain_3_2" end,props={base=0,resource=1,lair=0,territory=0},max_population=2,default_max_population=2}
    s.camp={id=11,name=function() return "red_smart_terrain_4_2" end,props={base=1,resource=0,lair=0,territory=0}}
    s.jup={id=12,name=function() return "jup_b208" end,props={base=1,resource=0,lair=0,territory=0},max_population=2,default_max_population=2}
    s.registry.red_smart_terrain_3_2={travel_hub=1}
    s.registry.red_smart_terrain_4_2={faction="greh",protect=true,resurrect=true}
    g.SIMBOARD={smarts_by_names={red_smart_terrain_3_2=s.mine,red_smart_terrain_4_2=s.camp,jup_b208=s.jup},smarts={[10]={squads={}},[11]={squads={}},[12]={squads={}}}}
    g.smart_terrain_warfare={uniques={jup_b208={1,1,0,0,0}},smart_owners={},last_seen={},
        get_main_base_faction=function(name) return s.registry[name] and s.registry[name].faction end,
        set_main_base=function(name,value) s.registry[name]=value end,
        is_main_base=function(name) return s.registry[name] and s.registry[name].faction~=nil end,
        actor_blind=function() return false end,
        smart_terrain_on_update=noop,squad_on_npc_death=noop}
    g.simulation_objects={get_props=noop}; g.xr_conditions={}
    g.alife_storage_manager={get_state=function() return s.save end}
    g.alife_object=function() end
    g.get_time=function() return 0 end
    g.round_idp=function(n) return math.floor(n+0.5) end
    g.warfare_log={tr_begin=noop,info=noop,debug=noop,warn=noop,banner=noop}
    g.warfare_options={options={factions={greh={spawn_on_new_game=true},isg={spawn_on_new_game=true}},spawn_speed_multiplier=1,monster_max_faction_respawn=1},update_settings=noop}
    g.warfare_levels={open_graph_gated_smarts=function()
        s.graph_calls=s.graph_calls+1
        if sin and s.new and s.warfare and not s.story and not s.redone and g.SIMBOARD.start_position_filled then
            assert(s.registry.red_smart_terrain_3_2.faction=="greh","SIN must apply BEFORE graph opening/seeding")
        end
        if s.graph_error then error("native graph failure") end
        return "graph",nil,"tail"
    end,supported_smarts=function() return pairs({}) end}
    g.warfare_presim={arm=noop};g.sim_offline_combat={get_ignore_list=function() return {} end}
    g.sim_squad_warfare={squad_on_update=noop,squad_on_npc_death=noop,set_target=noop}
    g.ini_file=function() return {section_for_each=function(_,fn) fn("red_smart_terrain_3_2") end,
        line_count=function() return 1 end,r_line=function() return true,"greh_sim_squad_novice","1" end} end
    g.RegisterScriptCallback=function(name,fn) assert(fn); s.callbacks[name]=s.callbacks[name] or {};s.callbacks[name][fn]=true end
    g.UnregisterScriptCallback=function(name,fn) if s.callbacks[name] then s.callbacks[name][fn]=nil end end
    local w=setmetatable({VERSION="1.6.11",get_stalker_pop_factor=function() return s.pop end,
        get_monster_pop_factor=function() return 1 end,arm_spawn_stagger=noop,
        is_squad_monster={},COVERT_BASES={},registered_squads={greh={},isg={}},
        owns_section=function() return true end,is_story_section=function() return false end,
        get_squad_section_faction=function() return "greh" end,
        reset_frame_clock=noop,actor_on_update=noop,save_state=noop,load_state=noop,squad_on_unregister=noop,on_game_load=noop}, {__index=g})
    w.spawn_squad=function(section,smart)
        assert(not s.loading,"Seeding on load is forbidden")
        local faction=section=="isg_sim_squad_novice" and "isg" or "greh"
        local squad={id=#s.spawns+100,get_squad_community=function() return faction end}
        s.spawns[#s.spawns+1]=section
        w.registered_squads[faction][squad.id]=true
        return squad
    end
    module(isg and sources.unisg or sources.walo,w); g.warfare=w
    if sin then
        local core=module(sources.core,setmetatable({}, {__index=g}))
        g.zzzzzz_walo_sin_hq_core=core; s.core=core
        local new,loaded=core.apply_new_game,core.apply_loaded
        core.apply_new_game=function() s.core_new=s.core_new+1; return new() end
        core.apply_loaded=function()
            assert(not s.warfare or s.native_first,"Native first-update handler must run first")
            s.core_load=s.core_load+1;return loaded()
        end
        s.bridge=module(sources.bridge,setmetatable({}, {__index=g}))
    else assert(not g.zzzzzz_walo_sin_hq_core) end
    function s:start()
        self.native_first=false
        if self.bridge and bridge_first then self.bridge.on_game_start() end
        w.on_game_start()
        if self.bridge and not bridge_first then self.bridge.on_game_start() end
    end
    function s:fire(name) for fn in pairs(self.callbacks[name] or {}) do fn() end end
    function s:count(name) local n=0;for _ in pairs(self.callbacks[name] or {}) do n=n+1 end;return n end
    function s:fill() g.warfare_options.options.random_starting_locations=self.random;self:fire("fill_start_position") end
    s.g,s.w=g,w
    return s
end

for _,kind in ipairs({"sin","unisg","both"}) do
    for _,bridge_first in ipairs({false,true}) do
        test(kind.." independent new game / load / Story switch; bridge-first="..tostring(bridge_first),function()
            local s=world(kind,bridge_first); s:start();s:fill()
            local sin,isg=kind~="unisg",kind~="sin"
            assert(#s.spawns==(isg and 4 or 2)) -- real native fill, two fixture greh squads plus native UNISG seeding
            assert((s.registry.red_smart_terrain_3_2.faction=="greh")==sin)
            assert((s.registry.jup_b208~=nil)==isg)
            assert((s.save.walo_unisg_hq_native_v03==true)==isg)
            assert(s:count("fill_start_position")==1 and s:count("actor_on_first_update")==1)
            if sin then assert(s.core_new==1 and s.mine.default_max_population==2) end
            local spawned=#s.spawns
            s.new=false;s.loading=true;s:start();s:fire("actor_on_first_update")
            assert(#s.spawns==spawned and (s.registry.jup_b208~=nil)==isg)
            if sin then assert(s.registry.red_smart_terrain_3_2.faction=="greh" and s.core_load==1) end
            -- Repeated loads and already-filled callback must never reseed.
            for _=1,3 do s:start();s:fire("actor_on_first_update");s:fill() end
            assert(#s.spawns==spawned and s:count("fill_start_position")==1)
            s.warfare=false;s:start();s:fire("actor_on_first_update")
            assert(not s.registry.red_smart_terrain_3_2.faction and not s.registry.jup_b208)
            assert(s.registry.red_smart_terrain_3_2.travel_hub==1 and #s.spawns==spawned)
            s.warfare=true
            s.story=true;s:start();s:fire("actor_on_first_update")
            assert(not s.registry.red_smart_terrain_3_2.faction and s.registry.red_smart_terrain_3_2.travel_hub==1)
            assert(s.registry.red_smart_terrain_4_2.faction=="greh" and not s.registry.jup_b208)
            assert(s.mine.props.base==0 and #s.spawns==spawned)
        end)
    end
end

for _,kind in ipairs({"sin","unisg","both"}) do
    for _,warfare in ipairs({false,true}) do
        test(kind.." unsupported Story new game warfare="..tostring(warfare),function()
            local s=world(kind,true);s.story=true;s.warfare=warfare;s:start();s:fill();s:fire("actor_on_first_update")
            assert(not s.registry.red_smart_terrain_3_2.faction and not s.registry.jup_b208)
            assert(not s.save.walo_unisg_hq_native_v03 and #s.spawns==(warfare and 2 or 0))
        end)
    end
    test(kind.." random-start early exit",function()
        local s=world(kind,false);s.random=true;s:start();s:fill()
        assert(#s.spawns==0 and not s.registry.jup_b208)
        if kind~="unisg" then assert(s.core_new==1 and s.registry.red_smart_terrain_3_2.faction=="greh") end
    end)
end

test("later callback wrappers preserve one handler and nil/multiple returns",function()
    local s=world("both",false);s:start()
    local f,a=s.w.fill_start_position,s.w.actor_on_first_update
    s.w.fill_start_position=function(...) f(...);return "fill",nil,"tail" end
    s.w.actor_on_first_update=function(...) a(...);return "first",nil,"tail" end
    for _=1,3 do s:start() end
    assert(s:count("fill_start_position")==1 and s:count("actor_on_first_update")==1)
    local x,y,z=s.w.fill_start_position();assert(x=="fill" and y==nil and z=="tail" and s.core_new==1)
    x,y,z=s.w.actor_on_first_update();assert(x=="first" and y==nil and z=="tail")
end)

test("delegated fill failure clears new-game scope; unrelated graph calls are untouched",function()
    local s=world("sin",true);s:start();s.graph_error=true
    assert(not pcall(s.w.fill_start_position) and s.core_new==1)
    s.graph_error=false
    local x,y,z=s.g.warfare_levels.open_graph_gated_smarts()
    assert(x=="graph" and y==nil and z=="tail" and s.core_new==1)
end)

test("legacy save with UNISG marker works without loading any UNISG source",function()
    local s=world("sin",false);s.new=false;s.loading=true;s.g.SIMBOARD.start_position_filled=true
    s.save.walo_unisg_hq_native_v03=true;s:start();s:fire("actor_on_first_update");s:fill()
    assert(#s.spawns==0 and not s.registry.jup_b208 and s.save.walo_unisg_hq_native_v03)
    assert(s.registry.red_smart_terrain_3_2.faction=="greh" and not s.w.unisg_hq_restore)
end)

test("UNISG alone and both retain identical native seeding, marker and service configuration",function()
    local a,b=world("unisg",false),world("both",true)
    a:start();a:fill();b:start();b:fill()
    assert(table.concat(a.spawns,",")==table.concat(b.spawns,","))
    assert(a.save.walo_unisg_hq_native_v03==b.save.walo_unisg_hq_native_v03)
    assert(a.jup.default_max_population==b.jup.default_max_population)
    for i=1,5 do assert(a.g.smart_terrain_warfare.uniques.jup_b208[i]==b.g.smart_terrain_warfare.uniques.jup_b208[i]) end
end)

for _,kind in ipairs({"unisg","both"}) do
    test(kind.." existing unmarked save never receives new UNISG squads",function()
        local s=world(kind,false);s.new=false;s.loading=true;s.g.SIMBOARD.start_position_filled=true
        s:start();s:fire("actor_on_first_update");s:fill()
        assert(#s.spawns==0 and not s.registry.jup_b208 and not s.save.walo_unisg_hq_native_v03)
    end)
end

test("population updates preserve both HQ capacities without seeding on load",function()
    local s=world("both",false);s.pop=0.5;s:start();s:fill()
    assert(s.mine.default_max_population==8 and s.jup.default_max_population==8)
    local spawned=#s.spawns
    s.pop=4;s.new=false;s.loading=true;s:start();s:fire("actor_on_first_update")
    assert(s.mine.default_max_population==1 and s.jup.default_max_population==1 and #s.spawns==spawned)
end)

test("Core ReDone exclusion leaves UNISG behavior independent",function()
    local s=world("both",true);s.redone=true;s:start();s:fill()
    assert(not s.registry.red_smart_terrain_3_2.faction and s.registry.jup_b208.faction=="isg")
end)
return passed
