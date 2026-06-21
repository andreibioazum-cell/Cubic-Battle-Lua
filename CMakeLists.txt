cmake_minimum_required(VERSION 3.10)
project(CubicBattleNative)

find_package(Lua REQUIRED)

add_library(native SHARED src/native.cpp)
set_target_properties(native PROPERTIES PREFIX "" OUTPUT_NAME "native")
target_include_directories(native PRIVATE ${LUA_INCLUDE_DIR})
if(TARGET Lua::Lua)
    target_link_libraries(native PRIVATE Lua::Lua)
else()
    target_link_libraries(native PRIVATE ${LUA_LIBRARIES})
endif()
