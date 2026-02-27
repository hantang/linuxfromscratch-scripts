#!/usr/bin/env bash
set -eu

LOCAL_ROOT="${1:-lfs-out}"
VERSION="${2:-13.0-systemd-rc1}"

echo "Save: $LOCAL_ROOT"
echo "version: $VERSION"

BASE_URL="https://www.linuxfromscratch.org/lfs/downloads/$VERSION/"
echo "Fetch file list ${BASE_URL}"
site_text=$(curl -s "$BASE_URL")
url_list=$(echo $site_text | grep -oE 'href="([^"]*\.html|wget-list[^"]*|md5sums)"' | sed 's/href="//;s/"//')

# convert texts to array
mapfile -t FILE_LIST < <(echo "$url_list")
echo "files: ${FILE_LIST[*]}"
echo ""

for filename in "${FILE_LIST[@]}"; do
    if [[ "$filename" == *.old ]]; then 
        continue
    fi
    output_path="${LOCAL_ROOT}/${VERSION}/${filename}"
    if [[ -f $output_path ]]; then
        echo "$output_path exists"
        continue
    fi

    full_url="${BASE_URL}${filename}"
    echo "Downloading $full_url"
    curl --silent --fail --create-dirs -o "$output_path" "$full_url" || echo "下载失败 ${filename}"
done
