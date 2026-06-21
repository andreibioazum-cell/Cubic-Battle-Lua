#!/usr/bin/env bash
set -euo pipefail
mkdir -p build
cd build
cmake ..
cmake --build . --target native
# copy produced library to project root so `require("native")` can find it
# on Linux the library will be named native.so; adjust if needed for your platform
cp native.so .. || true
echo "Built native module (copied native.so to project root)"