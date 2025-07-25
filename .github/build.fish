#!/usr/bin/env fish
set filename build.config.json

function buildRepo
    set name (basename $argv[1])
    set subdomain (jq -r ".[\"$name\"].subdomain" $filename)
    set repolink (jq -r ".[\"$name\"].repolink" $filename)
    set repodir ./buildfiles/$name
    set branch "main"   # always use main branch

    if test ! -e site
        mkdir site
    else
        rm -rf ./site/$subdomain
    end
    if test ! -e buildfiles
        mkdir buildfiles
    else
        rm -rf ./buildfiles/*
    end

    echo "Cloning repo: $repolink into $repodir on branch $branch"
    set authrepolink (string replace "https://" "https://$PA_TOKEN:@" $repolink)
    git clone -b $branch "$authrepolink" "$repodir"

    cd $repodir
    bun i
    bun run build
    cd -

    mkdir -p "./site/$subdomain"
    if test -e $repodir/build
        cp -r $repodir/build/* ./site/$subdomain
    else if test -e $repodir/dist
        cp -r $repodir/dist/* ./site/$subdomain
    end

    rm -r buildfiles
end

if test "$argv[1]" = "all"
    set keys (jq -r 'keys_unsorted | .[]' $filename)
    for i in $keys
        buildRepo "$i"
    end
else
    buildRepo "$argv[1]"
end
