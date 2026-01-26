
sudo apt install -y build-essential libgccjit-*-dev libxpm-dev libgif-dev

git clone https://github.com/tree-sitter/tree-sitter.git
cd tree-sitter
git checkout v0.26.3

make
sudo make install PREFIX=/usr/local
sudo ldconfig

git clone --depth 1 --branch emacs-30.1 https://git.savannah.gnu.org/git/emacs.git
cd emacs

./autogen.sh

export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig:/usr/local/share/pkgconfig
export CPPFLAGS="-I/usr/local/include"
export LDFLAGS="-L/usr/local/lib -Wl,-rpath,/usr/local/lib"
./configure --with-pgtk \
   --with-tree-sitter \
  --with-native-compilation \
  --without-x \
  --with-gnutls \
  --prefix=/usr/local

make -j"$(nproc)"
sudo make install
