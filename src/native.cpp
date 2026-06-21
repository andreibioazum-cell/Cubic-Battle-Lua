extern "C" {
#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>
}

#include <cmath>

static double ex = 0.0, ey = 0.0;
static int ehp = 5;
static int esize = 55;
static bool alive = false;
static double timer = 0.0;
static double respawn_time = 2.0;
static bool respawnEnabled = true;

static void spawn_enemy(double px, double py) {
    double a = (double)rand() / RAND_MAX * M_PI * 2.0;
    double dist = 300 + (double)rand() / RAND_MAX * 200.0;
    ex = px + cos(a) * dist;
    ey = py + sin(a) * dist;
    ehp = 5;
    alive = true;
    timer = 0.0;
}

static int l_enemy_update(lua_State* L) {
    double dt = luaL_checknumber(L, 1);
    double px = luaL_checknumber(L, 2);
    double py = luaL_checknumber(L, 3);

    if (!alive) {
        if (!respawnEnabled) return 0;
        timer += dt;
        if (timer >= respawn_time) {
            spawn_enemy(px, py);
        }
        return 0;
    }

    // simple wander-chase behavior towards player
    double dx = px - ex;
    double dy = py - ey;
    double dist = sqrt(dx*dx + dy*dy) + 1e-6;
    double nx = dx / dist;
    double ny = dy / dist;

    double speed = 140.0;
    if (dist < 60) {
        // retreat
        ex -= nx * speed * 0.5 * dt;
        ey -= ny * speed * 0.5 * dt;
    } else if (dist < 650) {
        // chase
        ex += nx * speed * dt;
        ey += ny * speed * dt;
    } else {
        // wander
        ex += (cos(timer*3.1) * 0.3) * speed * 0.2 * dt;
        ey += (sin(timer*2.2) * 0.3) * speed * 0.2 * dt;
    }
    timer += dt;

    lua_pushboolean(L, alive);
    return 1;
}

static int l_enemy_get(lua_State* L) {
    if (!alive) {
        lua_pushnil(L);
        return 1;
    }
    lua_newtable(L);
    lua_pushnumber(L, ex); lua_setfield(L, -2, "x");
    lua_pushnumber(L, ey); lua_setfield(L, -2, "y");
    lua_pushinteger(L, ehp); lua_setfield(L, -2, "hp");
    lua_pushinteger(L, esize); lua_setfield(L, -2, "size");
    return 1;
}

static int l_enemy_hit(lua_State* L) {
    if (!alive) return 0;
    int dmg = luaL_optinteger(L, 1, 1);
    ehp -= dmg;
    if (ehp <= 0) {
        alive = false;
        ehp = 0;
    }
    return 0;
}

static int l_enemy_reset(lua_State* L) {
    alive = false;
    timer = 0.0;
    return 0;
}

static int l_set_respawn(lua_State* L) {
    int b = lua_toboolean(L, 1);
    respawnEnabled = (b != 0);
    return 0;
}

static const luaL_Reg native_funcs[] = {
    {"enemy_update", l_enemy_update},
    {"enemy_get", l_enemy_get},
    {"enemy_hit", l_enemy_hit},
    {"enemy_reset", l_enemy_reset},
    {"set_respawn_enabled", l_set_respawn},
    {NULL, NULL}
};

extern "C" int luaopen_native(lua_State* L) {
#if LUA_VERSION_NUM >= 502
    luaL_newlib(L, native_funcs);
#else
    luaL_register(L, "native", native_funcs);
#endif
    return 1;
}
