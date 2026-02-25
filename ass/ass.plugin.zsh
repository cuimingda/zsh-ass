list_ass_fonts() {
  # 递归当前目录，提取所有 .ass 里的 \fn 字体名并去重排序输出
  find . -type f -name "*.ass" -print0 \
    | xargs -0 perl -ne 'while(/\\fn([^\\}]+)/g){ print "$1\n" }' \
    | sort -u
}

remove_ass_fonts() {
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