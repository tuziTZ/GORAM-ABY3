#!/bin/bash

# Configuration
TEST_NAME="bspn_test"

# Get script directory to resolve paths relatively
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")" # Assuming BSPN_Eval is at root
ABY3_DIR="${ROOT_DIR}/aby3"
FRONTEND_DIR="${ABY3_DIR}/frontend"

MAIN_CPP="${FRONTEND_DIR}/main.cpp"
MAIN_BSPN="${FRONTEND_DIR}/main.bspn"
MAIN_TEST="${FRONTEND_DIR}/main.test"

# Paths
debugFile="${ABY3_DIR}/debug_bspn.txt"
bspnDataFolder="${ABY3_DIR}/aby3-BSPN/data/"

# Create Data Folder if not exists
if [ ! -d "$bspnDataFolder" ]; then
    mkdir -p "$bspnDataFolder"
fi

echo "Setting up BSPN test..."

# 1. Swap main.cpp with main.bspn (This ensures our test function is hooked)
if [ -f "$MAIN_BSPN" ]; then
    echo "Using main.bspn as main.cpp"
    cp "$MAIN_BSPN" "$MAIN_CPP"
else
    echo "Error: main.bspn not found at $MAIN_BSPN!"
    exit 1
fi

# 2. Build the project using build.py
echo "Building project..."
cd "${ABY3_DIR}" || exit
# python3 ./build.py --Debug 
python3 ./build.py
# Assuming passing a flag or just running build default
# The build.py usually just builds what's in CMakeLists.txt
# Since we updated CMakeLists.txt in previous turn, it should include BSPN lib.
# Let's just run it. Using a flag --setup might be needed first time? 
# Usually just running it builds. The flags in unit_test.sh were for configuring. 
# unit_test.sh calls: python ./build.py --DEBUG_FILE ...
# python3 ./build.py --DEBUG_FILE ${debugFile}

if [ $? -ne 0 ]; then
    echo "Build failed!"
    exit 1
fi

# 3. Prepare run environment
echo "Running detailed BSPN Test..."

# Binary location might depend on build system.
# build.py typically puts output in `out/build/linux/frontend/frontend` or similiar.
# Let's find it.
BINARY_PATH="${ABY3_DIR}/out/build/linux/frontend/frontend"

if [ ! -f "$BINARY_PATH" ]; then
    echo "Binary not found at $BINARY_PATH. Searching..."
    BINARY_PATH=$(find "${ABY3_DIR}/out" -name frontend -type f | head -n 1)
    if [ -z "$BINARY_PATH" ]; then
         echo "Could not find frontend binary."
         exit 1
    fi
fi

echo "Using binary: $BINARY_PATH"

# Run 3 parties in background
$BINARY_PATH -bspn_test -role 0 &
P0_PID=$!

$BINARY_PATH -bspn_test -role 1 &
P1_PID=$!

$BINARY_PATH -bspn_test -role 2 &
P2_PID=$!

wait $P0_PID
wait $P1_PID
wait $P2_PID

echo "Test Finished."

