#!/usr/bin/env bash

function arg_required {
  if [[ -z "$2" ]]; then
    echo "Missing required argument: $1" >&2
    exit 1
  fi
}

while [ $# -gt 0 ]; do
  case $1 in
    -d | --dir)
      dir="$2"
      shift
      ;;
    -o | --output_file)
      output_file="$2"
      shift
      ;;
    *)
      echo "Invalid option: $1" >&2
      exit 1
      ;;
  esac
  shift
done

arg_required "dir" "$dir"
arg_required "output_file" "$output_file"

lifecycles=()
# Directory is considered to be a lifecycle if under 1 nested directory from the repo root and it has Makefile with help-p2p target
while IFS= read -r MAKEFILE; do
   if make -f "$MAKEFILE" help-p2p >/dev/null 2>&1; then
     # Strip the leading ./ from the path
     lifecycles+=("$(dirname "$MAKEFILE" | sed 's|.\/\(.*\)|\1|')")
   fi
done < <(find "$dir" -name Makefile -type f -maxdepth 2)
echo "${lifecycles[*]}" | jq -Rc 'split(" ")' > "$output_file"
