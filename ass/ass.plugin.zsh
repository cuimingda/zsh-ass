asshelp() {
  echo "list_ass_dialogue_fonts"
  echo "remove_ass_dialogue_fonts"
  echo "list_ass_style_fonts"
  echo "reset_ass_fonts"
}

list_ass_dialogue_fonts() {
  # 递归当前目录，提取所有 .ass 里的 \fn 字体名并去重排序输出
  find . -type f -name "*.ass" -print0 \
    | xargs -0 perl -ne 'while(/\\fn([^\\}]+)/g){ print "$1\n" }' \
    | sort -u
}

remove_ass_dialogue_fonts() {
  local f enc tmp

  find . -type f -name "*.ass" -print0 | while IFS= read -r -d '' f; do
    echo "Processing: $f"

    tmp="${f}.tmp.$$"
    enc="$(file -b "$f")"

    if echo "$enc" | grep -qi "utf-16"; then
      iconv -f UTF-16 -t UTF-8 "$f" \
        | tr -d '\r' \
        | perl -0777 -pe 's/\\fn[^\\}]+//g' \
        > "$tmp"
    else
      tr -d '\r' < "$f" \
        | perl -0777 -pe 's/\\fn[^\\}]+//g' \
        > "$tmp"
    fi

    mv "$tmp" "$f"
  done

  echo "Done. All \\fn tags removed."
}

# List fonts used in Style lines for all .ass files in the current directory.
# Output is grouped by file.
list_ass_style_fonts() {
  local files=(./*.ass(N))

  if (( ${#files[@]} == 0 )); then
    print -u2 "ass_style_fonts: no .ass files found in current directory"
    return 1
  fi

  local f
  for f in "${files[@]}"; do
    print "${f:t}:"
    awk '
      function trim(s){ gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
      function dequote(s){
        s=trim(s)
        if (s ~ /^".*"$/) { sub(/^"/,"",s); sub(/"$/,"",s) }
        return s
      }
      BEGIN { FS="," }
      $0 ~ /^Style:[ \t]*/ {
        line=$0
        sub(/^Style:[ \t]*/, "", line)
        n=split(line, a, ",")
        if (n >= 2) {
          font = dequote(a[2])
          if (font != "") fonts[font]=1
        }
      }
      END { for (k in fonts) print k }
    ' "$f" | LC_ALL=C sort | sed 's/^/  /'
    print ""
  done
}

# Replace all fonts in FONT_LIST with Microsoft YaHei
# in all .ass files in current directory (no backup)
reset_ass_fonts() {
  # === configurable font list ===
  local FONT_LIST=(
    "微软雅黑"
    "方正黑体_GBK"
  )

  local TARGET_FONT="Microsoft YaHei"

  local files=(./*.ass(N))

  if (( ${#files[@]} == 0 )); then
    print -u2 "reset_ass_fonts: no .ass files found"
    return 1
  fi

  local f font
  for f in "${files[@]}"; do
    print "Processing ${f:t}..."

    local sed_args=()
    for font in "${FONT_LIST[@]}"; do
      sed_args+=(-e "s/${font}/${TARGET_FONT}/g")
    done

    # macOS BSD sed: no backup requires empty suffix
    sed -i '' "${sed_args[@]}" "$f"
  done

  print "Done."
}