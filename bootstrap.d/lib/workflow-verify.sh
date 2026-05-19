# shellcheck shell=bash
# Verification helpers for bootstrap workflows (sourced from workflow.sh).

workflow_verify() {
  local id="${1:?verify id}"
  local fn="verify_${id}"
  if declare -f "$fn" >/dev/null 2>&1; then
    "$fn"
    return $?
  fi
  die "verification inconnue: $id"
}

verify_stack_running() {
  local ps_out
  ps_out="$(compose_stack ps --status running 2>/dev/null || true)"
  echo "$ps_out" | grep -qi backend
}

verify_http_ready() {
  local port="${HTTP_PUBLISH_PORT:-8080}"
  local code
  code="$(curl -s -o /dev/null -w '%{http_code}' --max-time 8 "http://127.0.0.1:${port}/" 2>/dev/null || echo "000")"
  case "$code" in
    000) return 1 ;;
    200|301|302|303|307|308|401|403|404|500|502|503) return 0 ;;
    *) return 1 ;;
  esac
}

verify_site_exists() {
  local site="${WF_SITE:?WF_SITE non defini}"
  compose_stack exec -T backend test -f \
    "/home/frappe/frappe-bench/sites/${site}/site_config.json" 2>/dev/null
}

verify_site_not_exists() {
  local site="${WF_SITE:?}"
  if verify_site_exists; then
    return 1
  fi
  return 0
}

verify_http_site_ready() {
  verify_http_ready && verify_site_exists
}

verify_app_installed() {
  local site="${WF_SITE:?}"
  compose_stack exec -T backend bench --site "$site" list-apps 2>/dev/null \
    | grep -q boutique_custom
}

verify_module_importable() {
  compose_stack exec -T backend bash -lc \
    'cd /home/frappe/frappe-bench && ./env/bin/python -c "import boutique_custom.setup.seed_boutique"' 2>/dev/null
}

verify_setup_complete() {
  local site="${WF_SITE:?}"
  local v
  v="$(compose_stack exec -T backend bench --site "$site" execute frappe.db.get_single_value \
    --kwargs '{"doctype":"System Settings","fieldname":"setup_complete"}' 2>/dev/null \
    | tr -d '[:space:]' || true)"
  [ "$v" = "1" ]
}

verify_setup_not_complete() {
  verify_setup_complete && return 1
  return 0
}

verify_migrate_no_lock() {
  compose_stack exec -T backend test ! -f \
    "/home/frappe/frappe-bench/sites/${WF_SITE}/locks/bench_migrate.lock" 2>/dev/null
}

verify_warehouse_exists() {
  local site="${WF_SITE:?}"
  local wh="${WF_WAREHOUSE:-Boutique}"
  local count
  count="$(compose_stack exec -T backend bench --site "$site" mariadb -N -e \
    "SELECT COUNT(*) FROM tabWarehouse WHERE warehouse_name='${wh}' OR name LIKE '%${wh}%'" 2>/dev/null \
    | tr -d '[:space:]' || echo 0)"
  [ "${count:-0}" -gt 0 ]
}

verify_pos_profile_exists() {
  local site="${WF_SITE:?}"
  local profile="${WF_POS_PROFILE:-Boutique}"
  compose_stack exec -T backend bench --site "$site" mariadb -N -e \
    "SELECT name FROM \`tabPOS Profile\` WHERE name='${profile}' LIMIT 1" 2>/dev/null \
    | grep -q .
}

verify_image_exists() {
  local image="${CUSTOM_IMAGE:-custom}"
  local tag="${CUSTOM_TAG:-16}"
  docker image inspect "${image}:${tag}" >/dev/null 2>&1
}

workflow_run_verifies() {
  local spec="$1"
  local id
  IFS=',' read -ra ids <<< "$spec"
  for id in "${ids[@]}"; do
    id="${id// /}"
    [ -n "$id" ] || continue
    log "verify: $id"
    if ! workflow_verify "$id"; then
      return 1
    fi
  done
  return 0
}

workflow_run_verifies_retry() {
  local spec="$1"
  local retries="${2:-3}"
  local delay="${3:-5}"
  local attempt=1
  while [ "$attempt" -le "$retries" ]; do
    if workflow_run_verifies "$spec"; then
      return 0
    fi
    if [ "$attempt" -lt "$retries" ]; then
      log "verification echouee (tentative ${attempt}/${retries}), nouvel essai dans ${delay}s..."
      sleep "$delay"
    fi
    attempt=$((attempt + 1))
  done
  return 1
}
