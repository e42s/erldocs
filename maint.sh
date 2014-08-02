#!/bin/bash

# Generate erldocs for Erlang/OTP's maint branch.

[[ $# -ne 1 ]] && echo "Usage: $0  ‹path to cloned repo›" && exit 1
idir="${1%%/}" # Remove trailing slash if exists
[[ ! -d "$idir"/.git ]] && echo "$idir is not a Git repo!" && exit 1

erldocs='./erldocs'
[[ ! -x "$erldocs" ]] && [[ ! -L "$erldocs" ]] && \
    echo "$erldocs executable not found!" && exit 1

release="maint"
odir="docs-$release"

site_root='site.git'
site="$site_root/$release"
[[ ! -d "$site" ]] && echo "maint site not found" && exit 1
archive='site.git/archives/${odir}.tar.bz2'

mkdir -p  "$odir" "$idir"
rm    -rf "$odir"/*

cd "$idir"
echo "Commencing pull & build of $release branch" \
    && git checkout maint \
    && git pull origin maint \
    && make clean all
cd -

includes="-I $idir"/erts/include
for dir in "$idir"/lib/*/include "$idir"/bootstrap/lib/*/include; do
    includes="$includes -I $dir"
done

"$erldocs"          \
    -o "$odir"      \
    $includes       \
    "$idir"/lib/*   \
    "$idir"/erts    \
    | tee _"$release"

rm -rf "$odir"/.xml
tar jcf "$odir".tar.bz2 "$odir"

rm -rf "$site"
mv "$odir" "$site"
mv "odir".tar.bz2 "$archive"

cd "$site_root"
git add "$release" "$archive"
git commit -m "Updated OTP's $release branch"
git pull origin gh-pages
git push origin gh-pages
cd -
