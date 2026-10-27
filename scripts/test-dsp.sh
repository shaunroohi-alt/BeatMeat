#!/bin/bash
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
cd "$root"
mkdir -p .build
"${CXX:-c++}" -std=c++17 -Wall -Wextra -Werror -O1 -g \
 -fsanitize=address,undefined -fno-omit-frame-pointer \
 Sources/Audio/BeatKernel.cpp Tests/KernelTests.cpp -o .build/kernel-tests
.build/kernel-tests
