# Build all project-local, vendored dependencies

echo "Building GLFW..."
pushd ./vendor/glfw
cmake -S ./ -B ./build
cd ./build
make
popd
pwd
return

echo "Building epoxy..."
pushd ./vendor/libepoxy
mkdir -p _build
cd _build
meson
ninja
popd

echo "Building freetype..."
pushd ./vendor/freetype
./autogen.sh
./configure --prefix $(pwd)/build
make
make install
popd
