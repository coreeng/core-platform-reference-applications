#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
fixture_dir=$(mktemp -d)
trap 'rm -rf "$fixture_dir"' EXIT

mkdir -p "$fixture_dir/bin" "$fixture_dir/templates" "$fixture_dir/reference-apps/.github/workflows"
export RENDER_TEST_FIXTURES="$fixture_dir/templates"
export PATH="$fixture_dir/bin:$PATH"

cat > "$fixture_dir/bin/corectl" <<'CORECTL'
#!/usr/bin/env bash
set -euo pipefail
case "$1 $2" in
  'template list')
    printf '%s\n' portal-app disabled-app public-app monitoring infra
    ;;
  'template render')
    template=$3
    destination=$4
    mkdir -p "$destination/.github/workflows"
    cp "$RENDER_TEST_FIXTURES/$template.yaml" "$destination/app.yaml"
    for workflow in fast-feedback extended-test prod scheduled-security-scan; do
      cat > "$destination/.github/workflows/$workflow.yaml" <<'YAML'
name: Example
on:
  schedule:
    - cron: '0 0 * * *'
  workflow_dispatch: {}
jobs: {}
YAML
    done
    ;;
  *) exit 1 ;;
esac
CORECTL
chmod +x "$fixture_dir/bin/corectl"

for template in portal-app disabled-app public-app; do
  enabled=true
  type=portal
  [[ "$template" == disabled-app ]] && enabled=false
  [[ "$template" == public-app ]] && type=public
  cat > "$fixture_dir/templates/$template.yaml" <<YAML
name: reference-$template
config:
  ingress:
    enabled: $enabled
    type: $type
  replicas: 3
YAML
done
printf 'name: reference-monitoring\nconfig: {}\n' > "$fixture_dir/templates/monitoring.yaml"
printf 'name: reference-infra\n' > "$fixture_dir/templates/infra.yaml"
printf 'working_directory: ./\n' > "$fixture_dir/args.yaml"

cd "$fixture_dir"
git -C reference-apps init --quiet
git -C reference-apps config user.name 'Rendering test'
git -C reference-apps config user.email 'rendering-test@example.invalid'

render() {
  bash "$script_dir/collect_changed_templates.sh" -t templates -r reference-apps \
    -o changed.json -a args.yaml
}
render

yq -e '.config.ingress.enabled == true and .config.ingress.type == "public" and .config.replicas == 3' \
  reference-apps/reference-portal-app/app.yaml > /dev/null
yq -e '.config.ingress.enabled == false and .config.ingress.type == "portal"' \
  reference-apps/reference-disabled-app/app.yaml > /dev/null
cmp templates/disabled-app.yaml reference-apps/reference-disabled-app/app.yaml
cmp templates/public-app.yaml reference-apps/reference-public-app/app.yaml
cmp templates/monitoring.yaml reference-apps/reference-monitoring/app.yaml
cmp templates/infra.yaml reference-apps/reference-infra/app.yaml
jq -e 'sort == ["disabled-app", "infra", "monitoring", "portal-app", "public-app"]' changed.json > /dev/null

# A second render must preserve the override and produce no new changes.
git -C reference-apps -c commit.gpgsign=false commit --quiet -m 'Initial render'
render
jq -e '. == []' changed.json > /dev/null
git -C reference-apps diff --exit-code HEAD
printf 'Reference rendering ingress regression checks passed\n'
