#!/usr/bin/env bash


function arg_required {
  if [[ -z "$2" ]]; then
    echo "Missing required argument: $1" >&2
    exit 1
  fi
}

while [ $# -gt 0 ]; do
  case $1 in
    -t | --templates_dir)
      templates_dir="$2"
      shift
      ;;
    -r | --reference_apps_dir)
      reference_apps_dir="$2"
      shift
      ;;
    -o | --output_file)
      output_file="$2"
      shift
      ;;
    -a | --args-file )
      args_file="$2"
      shift
      ;;
    *)
      echo "Invalid option: $1" >&2
      exit 1
      ;;
  esac
  shift
done

arg_required "templates_dir" "$templates_dir"
arg_required "reference_apps_dir" "$reference_apps_dir"
arg_required "output_file" "$output_file"

set -euo pipefail

mapfile -t all_templates < <(corectl template list --templates "$templates_dir")
changed_templates=()
for t in "${all_templates[@]}"; do
  echo "Rendering template '$t'"
  rm -rf "./$reference_apps_dir/$t"
  mkdir -p "./$reference_apps_dir/$t"
  corectl template render "$t" "./$reference_apps_dir/$t" \
    --templates "$templates_dir" \
    --args-file "$args_file" \
    -a "name=$t" \
    -a "tenant=$t" \
    -a "working_directory=$t" \
    -a "version_prefix=$t/v"

  if [[ -d "./$reference_apps_dir/$t/.github/workflows" ]]; then
    mkdir -p "./$reference_apps_dir/.github/workflows"
    for workflow in fast-feedback extended-test prod; do
      if [[ -f "./$reference_apps_dir/$t/.github/workflows/$workflow.yaml" ]]; then
        mv "./$reference_apps_dir/$t/.github/workflows/$workflow.yaml" \
          "./$reference_apps_dir/.github/workflows/$t-$workflow.yaml"
      fi
    done
    rmdir "./$reference_apps_dir/$t/.github/workflows" 2>/dev/null || true
    rmdir "./$reference_apps_dir/$t/.github" 2>/dev/null || true
  fi

  git -C "./$reference_apps_dir" add "./$t"
  git -C "./$reference_apps_dir" add "./.github/workflows/$t-fast-feedback.yaml" \
    "./.github/workflows/$t-extended-test.yaml" \
    "./.github/workflows/$t-prod.yaml"
  if [[ "$(git -C "$reference_apps_dir" status "./$t" --untracked-files=no --porcelain)" ]]; then
    echo "Template '$t' has changed!"
    changed_templates+=("$t")
  elif [[ "$(git -C "$reference_apps_dir" status \
    "./.github/workflows/$t-fast-feedback.yaml" \
    "./.github/workflows/$t-extended-test.yaml" \
    "./.github/workflows/$t-prod.yaml" \
    --untracked-files=no --porcelain)" ]]; then
    echo "Template '$t' workflows have changed!"
    changed_templates+=("$t")
  fi
done
ct_json=$(echo "${changed_templates[*]}" | jq -Rc 'split(" ")')
echo "$ct_json" > "$output_file"
