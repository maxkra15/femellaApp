#!/bin/bash
OLD="FemellaAppRevamp"
NEW="femella"

# 1. Replace text in files
find . -type f -not -path "*/.git/*" -not -path "*/.build/*" -not -name "rename_project.sh" -exec grep -Il "$OLD" {} + | while read file; do
    sed -i '' "s/$OLD/$NEW/g" "$file"
done

# 2. Rename files and directories (deepest first to avoid breaking paths)
find . -depth -name "*$OLD*" -not -path "*/.git/*" | while read path; do
    dir=$(dirname "$path")
    base=$(basename "$path")
    new_base=${base//$OLD/$NEW}
    mv "$path" "$dir/$new_base"
done

echo "Project renamed from $OLD to $new_base successfully."
