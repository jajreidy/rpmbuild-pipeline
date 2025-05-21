#! /bin/bash

diff_flavor=$1
test -z "$diff_flavor" && {
    echo "Missing argument, execute either of those:"
    echo "  $0 fedora"
    exit 1
}

set -x

TMPDIR=$(mktemp -d /tmp/compare-rpmbuild-pipeline-XXXXXX)

files_to_diff="
pipeline/build-rpm-package.yaml
task/calculate-deps.yaml
task/check-noarch.yaml
task/get-rpm-sources.yaml
task/import-to-quay.yaml
task/rpmbuild.yaml
renovate.json
diff-flavor.sh
"

case $diff_flavor in
fedora)
    overrides=( "pipeline/build-rhel-package.yaml pipeline/build-rpm-package.yaml" )
    raw_link=https://gitlab.com/fedora/infrastructure/konflux/rpmbuild-pipeline/-/raw/main
    ;;
esac

for file in $files_to_diff; do
    url=$raw_link/$file
    for override in "${overrides[@]}"; do
        set -- $override
        if test "$1" == "$file"; then
            url=$raw_link/$2
            break
        fi
    done
    dest=$TMPDIR/$file
    (
        cd "$TMPDIR"
        mkdir -p "$(dirname "$file")"
    )
    curl "$url" > "$dest" 2>/dev/null
    vim -d "$file" "$dest"
done

