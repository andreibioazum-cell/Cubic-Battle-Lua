Build and install native C++ module (Linux)

Requirements:
- CMake
- A system Lua development package (headers + library)

Build steps:

```bash
mkdir -p build && cd build
cmake ..
cmake --build . --target native
# After build, copy produced native.so to project root so Lua can require("native")
cp native.so ..
```

If `require("native")` fails, the code falls back to pure-Lua enemy implementation.
