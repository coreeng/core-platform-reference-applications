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
  reference_t="reference-$t"
  echo "Rendering template '$t'"
  rm -rf "./$reference_apps_dir/$reference_t"
  mkdir -p "./$reference_apps_dir/$reference_t"
  corectl template render "$t" "./$reference_apps_dir/$reference_t" \
    --templates "$templates_dir" \
    --args-file "$args_file" \
    -a "name=$reference_t" \
    -a "tenant=$reference_t" \
    -a "working_directory=$reference_t" \
    -a "version_prefix=$reference_t/v"

  if [[ -d "./$reference_apps_dir/$reference_t/.github/workflows" ]]; then
    mkdir -p "./$reference_apps_dir/.github/workflows"
    for workflow in fast-feedback extended-test prod scheduled-security-scan; do
      if [[ -f "./$reference_apps_dir/$reference_t/.github/workflows/$workflow.yaml" ]]; then
        workflow_file="./$reference_apps_dir/.github/workflows/$reference_t-$workflow.yaml"
        mv "./$reference_apps_dir/$reference_t/.github/workflows/$workflow.yaml" "$workflow_file"
        yq -i 'del(.on.schedule)' "$workflow_file"
      fi
    done
    rmdir "./$reference_apps_dir/$reference_t/.github/workflows" 2>/dev/null || true
    rmdir "./$reference_apps_dir/$reference_t/.github" 2>/dev/null || true
  fi

  git -C "./$reference_apps_dir" add "./$reference_t"
  git -C "./$reference_apps_dir" add "./.github/workflows/$reference_t-fast-feedback.yaml" \
    "./.github/workflows/$reference_t-extended-test.yaml" \
    "./.github/workflows/$reference_t-prod.yaml" \
    "./.github/workflows/$reference_t-scheduled-security-scan.yaml"
  if [[ "$(git -C "$reference_apps_dir" status "./$reference_t" --untracked-files=no --porcelain)" ]]; then
    echo "Template '$t' has changed!"
    changed_templates+=("$t")
  elif [[ "$(git -C "$reference_apps_dir" status \
    "./.github/workflows/$reference_t-fast-feedback.yaml" \
    "./.github/workflows/$reference_t-extended-test.yaml" \
    "./.github/workflows/$reference_t-prod.yaml" \
    "./.github/workflows/$reference_t-scheduled-security-scan.yaml" \
    --untracked-files=no --porcelain)" ]]; then
    echo "Template '$t' workflows have changed!"
    changed_templates+=("$t")
  fi
done
ct_json=$(echo "${changed_templates[*]}" | jq -Rc 'split(" ")')
echo "$ct_json" > "$output_file"
