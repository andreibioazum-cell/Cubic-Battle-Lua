// native_particles.cpp - C++ particle engine for LÖVE
extern "C" {
    #include <lua.h>
    #include <lauxlib.h>
    #include <lualib.h>
}

#include <cmath>
#include <cstdlib>
#include <ctime>

#define MAX_PARTICLES 5000

struct Particle {
    float x, y, vx, vy;
    float life, maxLife;
    float size, r, g, b;
};

static Particle particles[MAX_PARTICLES];
static Particle pool[1000];
static int particleCount = 0;
static int poolCount = 0;

static int native_spawn(lua_State* L) {
    if (particleCount >= MAX_PARTICLES) return 0;
    
    float x = luaL_checknumber(L, 1);
    float y = luaL_checknumber(L, 2);
    float spread = luaL_checknumber(L, 3);
    float life = luaL_checknumber(L, 4);
    float size = luaL_checknumber(L, 5);
    float r = luaL_checknumber(L, 6);
    float g = luaL_checknumber(L, 7);
    float b = luaL_checknumber(L, 8);
    
    Particle* p;
    if (poolCount > 0) {
        p = &pool[--poolCount];
    } else {
        p = &particles[particleCount];
    }
    
    float angle = (float)(rand()) / RAND_MAX * 6.283185307f;
    float speed = (float)(rand()) / RAND_MAX * spread;
    
    p->x = x; p->y = y;
    p->vx = cosf(angle) * speed;
    p->vy = sinf(angle) * speed;
    p->life = life * (0.5f + (float)(rand()) / RAND_MAX * 0.5f);
    p->maxLife = p->life;
    p->size = size;
    p->r = r; p->g = g; p->b = b;
    
    particleCount++;
    return 0;
}

static int native_burst(lua_State* L) {
    float x = luaL_checknumber(L, 1);
    float y = luaL_checknumber(L, 2);
    int count = luaL_checkinteger(L, 3);
    float spread = luaL_checknumber(L, 4);
    float life = luaL_checknumber(L, 5);
    float size = luaL_checknumber(L, 6);
    float r = luaL_checknumber(L, 7);
    float g = luaL_checknumber(L, 8);
    float b = luaL_checknumber(L, 9);
    
    for (int i = 0; i < count && particleCount < MAX_PARTICLES; i++) {
        Particle* p;
        if (poolCount > 0) {
            p = &pool[--poolCount];
        } else {
            p = &particles[particleCount];
        }
        
        float angle = (float)(rand()) / RAND_MAX * 6.283185307f;
        float speed = (float)(rand()) / RAND_MAX * spread;
        
        p->x = x; p->y = y;
        p->vx = cosf(angle) * speed;
        p->vy = sinf(angle) * speed;
        p->life = life * (0.5f + (float)(rand()) / RAND_MAX * 0.5f);
        p->maxLife = p->life;
        p->size = size;
        p->r = r; p->g = g; p->b = b;
        
        particleCount++;
    }
    return 0;
}

static int native_update(lua_State* L) {
    float dt = luaL_checknumber(L, 1);
    
    for (int i = 0; i < particleCount; ) {
        Particle* p = &particles[i];
        p->x += p->vx * dt;
        p->y += p->vy * dt;
        p->vx *= 0.98f;
        p->vy *= 0.98f;
        p->life -= dt;
        
        if (p->life <= 0.0f) {
            if (poolCount < 1000) {
                pool[poolCount++] = *p;
            }
            particles[i] = particles[--particleCount];
        } else {
            i++;
        }
    }
    return 0;
}

static int native_count(lua_State* L) {
    lua_pushinteger(L, particleCount);
    return 1;
}

static int native_get(lua_State* L) {
    int idx = luaL_checkinteger(L, 1) - 1;
    if (idx < 0 || idx >= particleCount) {
        lua_pushnil(L);
        return 1;
    }
    
    Particle* p = &particles[idx];
    lua_pushnumber(L, p->x);
    lua_pushnumber(L, p->y);
    lua_pushnumber(L, p->size);
    lua_pushnumber(L, p->life / p->maxLife);
    lua_pushnumber(L, p->r);
    lua_pushnumber(L, p->g);
    lua_pushnumber(L, p->b);
    return 7;
}

static int native_clear(lua_State* L) {
    particleCount = 0;
    poolCount = 0;
    return 0;
}

extern "C" int luaopen_native(lua_State* L) {
    srand(time(nullptr));
    
    luaL_Reg reg[] = {
        {"spawn", native_spawn},
        {"burst", native_burst},
        {"update", native_update},
        {"count", native_count},
        {"get", native_get},
        {"clear", native_clear},
        {nullptr, nullptr}
    };
    
    luaL_newlib(L, reg);
    return 1;
}
