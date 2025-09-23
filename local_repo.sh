#本地构建
sudo -u builder yay -G fbterm
cd fbterm/
sudo -u builder makepkg -sc
cp fbterm-1.7_5-5-x86_64.pkg.tar.zst ../local_repo/

cd ..
cat >> "pacman.conf" << EOF

[archlinuxcn]
SigLevel = Optional TrustAll
Server = https://mirrors.tuna.tsinghua.edu.cn/archlinuxcn/\$arch
[local]
SigLevel = Optional TrustAll
Server = file:///local_repo
EOF

repo-add local_repo/local.db.tar.gz local_repo/fbterm-1.7_5-5-x86_64.pkg.tar.zst 
repo-add my_local.db.tar.gz fbterm-1.7_5-5-x86_64.pkg.tar.zst
repo-add my_local.db.tar.gz fbterm-1.7_5-5-x86_64.pkg.tar.zst

mkdir -p /tmp/dummydb
mkdir -p /tmp/dummydb1

pacman --dbpath /tmp/dummydb --config pacman.conf -Sy
pacman --dbpath /tmp/dummydb1 --config pacman.conf -Sy
pacman --dbpath /tmp/dummydb --config pacman.conf -Sp fbterm
pacman --dbpath /tmp/dummydb1 --config pacman.conf -Sp fbterm

pacman --dbpath /tmp/dummydb --config pacman.conf -S fbterm


pacman -Ss fbterm