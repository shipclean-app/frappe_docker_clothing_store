# shellcheck shell=bash
# Bootstrap workflow engine (sourced from bootstrap via cmd_workflow).

WF_WORKFLOWS_DIR="${ROOT_DIR}/project/boutique_retail/workflows"
WF_STATE_DIR="${ROOT_DIR}/.bootstrap"
WF_STATE_FILE="${WF_STATE_DIR}/workflow-state.json"
WF_LOG_FILE="${WF_STATE_DIR}/workflow.log"
WF_PARSE_PY="${ROOT_DIR}/bootstrap.d/lib/workflow-parse.py"

# shellcheck source=bootstrap.d/lib/workflow-verify.sh
source "${ROOT_DIR}/bootstrap.d/lib/workflow-verify.sh"

WF_SITE=""
WF_ADMIN_PASSWORD="admin"
WF_WAREHOUSE="Boutique"
WF_POS_PROFILE="Boutique"
WF_YES=0
WF_SKIP_BACKUP=0
WF_SKIP_BUILD=0
WF_SKIP_TRANSLATIONS=0
WF_WITH_CATALOG=0
WF_DRY_RUN=0
WF_NON_INTERACTIVE=0
WF_FORCE_RECREATE_SITE=0
WF_TRANSLATION_CSV=""
WF_FROM_STEP=""
WF_UNTIL_STEP=""
WF_VERIFY_ONLY=0
WF_CURRENT_WORKFLOW=""
WF_EXPANDED_JSON=""

workflow_ensure_dirs() {
  mkdir -p "$WF_STATE_DIR"
}

workflow_log_file() {
  workflow_ensure_dirs
  printf '%s %s\n' "$(date -Iseconds)" "$*" >>"$WF_LOG_FILE"
}

workflow_save_state() {
  local workflow="$1" step_id="$2" index="$3" total="$4"
  workflow_ensure_dirs
  python3 - "$WF_STATE_FILE" "$workflow" "$step_id" "$index" "$total" "$WF_SITE" <<'PY'
import json, sys
from datetime import datetime, timezone

path, workflow, step_id, index, total, site = sys.argv[1:7]
data = {
    "workflow": workflow,
    "step_id": step_id,
    "step_index": int(index),
    "step_total": int(total),
    "site": site,
    "timestamp": datetime.now(timezone.utc).isoformat(),
}
open(path, "w", encoding="utf-8").write(json.dumps(data, indent=2) + "\n")
PY
}

workflow_fail() {
  local step_id="$1" index="$2" total="$3" msg="${4:-}"
  log "ECHEC a l'etape « ${step_id} » ($((index + 1))/${total})"
  [ -n "$msg" ] && log "$msg"
  log "Reprise : ./bootstrap workflow resume"
  log "Ou       : ./bootstrap workflow run ${WF_CURRENT_WORKFLOW} --from-step ${step_id}"
  log "Log      : ${WF_LOG_FILE}"
  exit 1
}

workflow_resolve_url() {
  local port="${HTTP_PUBLISH_PORT:-8080}"
  printf 'http://localhost:%s' "$port"
}

workflow_codespaces_hint() {
  if [ "${CODESPACES:-}" = "true" ] || [ -n "${CODESPACE_NAME:-}" ]; then
    printf '\n  Codespaces : onglet Ports VS Code → port %s (Forwarded Address)\n' \
      "${HTTP_PUBLISH_PORT:-8080}"
    printf '  Git push   : unset GITHUB_TOKEN GH_TOKEN avant git push si erreur 403\n'
  fi
}

workflow_pause() {
  local title="$1"
  shift
  local url="${1:-}"
  shift || true
  local -a checklist=()
  local -a link_lines=()
  while [ "$#" -gt 0 ]; do
    if [[ "$1" == *$'\t'* ]]; then
      link_lines+=("$1")
    else
      checklist+=("$1")
    fi
    shift
  done
  printf '\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
  printf '  ETAPE MANUELLE : %s\n' "$title"
  printf '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
  if [ "${#link_lines[@]}" -gt 0 ]; then
    printf '\n  Liens ERPNext (copier-coller) :\n'
    local item label link_url
    for item in "${link_lines[@]}"; do
      label="${item%%$'\t'*}"
      link_url="${item#*$'\t'}"
      printf '    • %s\n      %s\n' "$label" "$link_url"
    done
  elif [ -n "$url" ]; then
    printf '  URL      : %s\n' "$url"
  fi
  printf '  Site     : %s\n' "$WF_SITE"
  printf '  Admin    : %s\n' "$WF_ADMIN_PASSWORD"
  workflow_codespaces_hint
  if [ "${#checklist[@]}" -gt 0 ]; then
    printf '\n  Checklist :\n'
    for item in "${checklist[@]}"; do
      printf '  - %s\n' "$item"
    done
  fi
  if [ "$WF_NON_INTERACTIVE" -eq 1 ]; then
    log "[non-interactif] pause « ${title} » — poursuite automatique"
    return 0
  fi
  printf '\n  Appuyez sur Entree quand c est termine...'
  read -r _
}

workflow_flag_set() {
  case "$1" in
    skip_backup) [ "$WF_SKIP_BACKUP" -eq 1 ] ;;
    skip_build) [ "$WF_SKIP_BUILD" -eq 1 ] ;;
    skip_translations) [ "$WF_SKIP_TRANSLATIONS" -eq 1 ] ;;
    *) return 1 ;;
  esac
}

workflow_step_get() {
  local field="$1"
  python3 -c "
import json,sys
d=json.load(sys.stdin)
step=d['steps'][int(sys.argv[1])]
key=sys.argv[2]
val=step.get(key,'')
if isinstance(val,(list,dict)):
    import json as j
    print(j.dumps(val))
else:
    print(val)
" "$2" "$field" <<<"$WF_EXPANDED_JSON"
}

workflow_expand_workflow() {
  local name="$1"
  local wf_file="${WF_WORKFLOWS_DIR}/${name}.yaml"
  [ -f "$wf_file" ] || die "workflow introuvable: ${name} (${wf_file})"

  local base
  base="$(workflow_resolve_url)"
  local parse_args=(
    "site=${WF_SITE}"
    "admin_password=${WF_ADMIN_PASSWORD}"
    "warehouse=${WF_WAREHOUSE}"
    "pos_profile=${WF_POS_PROFILE}"
    "base_url=${base}"
    "pos_url=${base}/app/point-of-sale"
    "sales_tax_list_url=${base}/app/sales-taxes-and-charges-template"
    "sales_tax_new_url=${base}/app/sales-taxes-and-charges-template/new-sales-taxes-and-charges-template"
    "pos_profile_url=${base}/app/pos-profile/${WF_POS_PROFILE}"
    "translation_report=${ROOT_DIR}/project/boutique_retail/reports/translation-gaps-retail-fr.csv"
    "glossaire=${ROOT_DIR}/project/boutique_retail/glossaire_traduction_fr.md"
  )

  WF_EXPANDED_JSON="$(python3 "$WF_PARSE_PY" "$wf_file" "${parse_args[@]}")"
  WF_CURRENT_WORKFLOW="$name"
}

workflow_step_count() {
  python3 -c "import json,sys; print(len(json.load(sys.stdin)['steps']))" <<<"$WF_EXPANDED_JSON"
}

workflow_list_workflows() {
  local f name
  log "Workflows disponibles:"
  for f in "${WF_WORKFLOWS_DIR}"/*.yaml; do
    [ -f "$f" ] || continue
    name="$(basename "$f" .yaml)"
    [[ "$name" == _* ]] && continue
    printf '  - %s\n' "$name"
  done
}

workflow_describe() {
  local name="$1"
  workflow_expand_workflow "$name"
  python3 -c "
import json,sys
d=json.load(sys.stdin)
print(d.get('description',''))
print()
if d.get('limits'):
    print('Limites:')
    for x in d['limits']:
        print(f'  - {x}')
    print()
print('Etapes:')
for i,s in enumerate(d['steps'],1):
    t=s.get('type') or ('command' if s.get('command') else '?')
    print(f\"  {i}. [{s.get('id','?')}] {t}\" + (f\" → {s.get('command','')}\" if s.get('command') else ''))
" <<<"$WF_EXPANDED_JSON"
}

workflow_run_bootstrap_cmd() {
  local destructive=0
  case "${1:-}" in
    wipe|build|site-create) destructive=1 ;;
  esac
  if [ "$WF_DRY_RUN" -eq 1 ] && [ "$destructive" -eq 1 ]; then
    log "[dry-run] ./bootstrap $*"
    return 0
  fi
  log "exec: ./bootstrap $*"
  workflow_log_file "CMD ./bootstrap $*"
  "$ROOT_DIR/bootstrap" "$@"
}

workflow_execute_step() {
  local idx="$1"
  local step_json
  step_json="$(python3 -c "
import json,sys
print(json.dumps(json.load(sys.stdin)['steps'][int(sys.argv[1])]))
" "$idx" <<<"$WF_EXPANDED_JSON")"

  local step_id step_type
  step_id="$(python3 -c "import json,sys; print(json.load(sys.stdin).get('id','step'))" <<<"$step_json")"
  step_type="$(python3 -c "
import json,sys
s=json.load(sys.stdin)
print(s.get('type') or ('command' if s.get('command') else 'unknown'))
" <<<"$step_json")"

  # skip_if_flag
  local skip_flag
  skip_flag="$(python3 -c "import json,sys; print(json.load(sys.stdin).get('skip_if_flag',''))" <<<"$step_json")"
  if [ -n "$skip_flag" ] && workflow_flag_set "$skip_flag"; then
    log "skip: ${step_id} (${skip_flag})"
    return 0
  fi

  # skip_if_verify (skip step if verify passes)
  local skip_verify
  skip_verify="$(python3 -c "import json,sys; print(json.load(sys.stdin).get('skip_if_verify',''))" <<<"$step_json")"
  if [ -n "$skip_verify" ] && workflow_run_verifies "$skip_verify"; then
    log "skip: ${step_id} (${skip_verify} OK)"
    return 0
  fi

  # skip if site exists (site-create)
  local skip_if_site
  skip_if_site="$(python3 -c "import json,sys; print(json.load(sys.stdin).get('skip_if_site_exists',0))" <<<"$step_json")"
  if [ "$skip_if_site" = "1" ] || [ "$skip_if_site" = "True" ]; then
    if [ "$WF_FORCE_RECREATE_SITE" -eq 0 ] && verify_site_exists 2>/dev/null; then
      log "skip: ${step_id} (site ${WF_SITE} existe deja)"
      return 0
    fi
  fi

  # skip wizard pause if setup already complete
  local skip_if_setup
  skip_if_setup="$(python3 -c "import json,sys; print(json.load(sys.stdin).get('skip_if_setup_complete',0))" <<<"$step_json")"
  if [ "$skip_if_setup" = "1" ] || [ "$skip_if_setup" = "True" ]; then
    if verify_setup_complete 2>/dev/null; then
      log "skip: ${step_id} (wizard deja termine)"
      return 0
    fi
  fi

  # skip build if image exists and skip_build
  if [ "$step_id" = "build" ] || [ "$(python3 -c "import json,sys; print(json.load(sys.stdin).get('command',''))" <<<"$step_json")" = "build" ]; then
    if [ "$WF_SKIP_BUILD" -eq 1 ] && verify_image_exists 2>/dev/null; then
      log "skip: build (image existe, --skip-build)"
      return 0
    fi
  fi

  if [ "$WF_VERIFY_ONLY" -eq 1 ]; then
    local ver_spec
    ver_spec="$(python3 -c "
import json,sys
s=json.load(sys.stdin)
v=s.get('verify') or s.get('verify_after') or []
if isinstance(v,list):
    ids=[]
    for x in v:
        ids.append(x if isinstance(x,str) else x.get('id',''))
    print(','.join(ids))
elif isinstance(v,str):
    print(v)
" <<<"$step_json")"
    if [ -n "$ver_spec" ]; then
      workflow_run_verifies "$ver_spec" || workflow_fail "$step_id" "$idx" "$(workflow_step_count)" "verify-only echoue"
    else
      log "verify-only: ${step_id} (pas de verify definie)"
    fi
    return 0
  fi

  workflow_log_file "START ${step_id} (${step_type})"

  case "$step_type" in
    command)
      local cmd args_json arg extra_args=()
      cmd="$(python3 -c "import json,sys; print(json.load(sys.stdin).get('command',''))" <<<"$step_json")"
      if [ "$WF_DRY_RUN" -eq 1 ]; then
        log "[dry-run] ./bootstrap ${cmd} (etape ${step_id})"
        return 0
      fi
      mapfile -d '' extra_args < <(
        python3 -c "
import json,sys
for a in json.load(sys.stdin).get('args') or []:
    print(a, end='\0')
" <<<"$step_json"
      )
      local i
      for i in "${!extra_args[@]}"; do
        extra_args[$i]="${extra_args[$i]//\$\{site\}/$WF_SITE}"
        extra_args[$i]="${extra_args[$i]//\$\{admin_password\}/$WF_ADMIN_PASSWORD}"
        extra_args[$i]="${extra_args[$i]//\$\{warehouse\}/$WF_WAREHOUSE}"
      done

      if [ "$cmd" = "setup-boutique" ]; then
        extra_args=("$WF_SITE")
        [ "$WF_WITH_CATALOG" -eq 1 ] && extra_args+=(--with-catalog)
      fi

      if [ "$cmd" = "translation-import" ]; then
        if [ -z "$WF_TRANSLATION_CSV" ]; then
          log "AVERTISSEMENT: --translation-csv absent, import saute"
          log "  Relancer: ./bootstrap translation-import ${WF_SITE} <votre-csv-revu.csv>"
          return 0
        fi
        extra_args=("$WF_SITE" "$WF_TRANSLATION_CSV")
      fi

      local retry delay attempt=1 max_retry
      max_retry="$(python3 -c "import json,sys; print(json.load(sys.stdin).get('retry',1))" <<<"$step_json")"
      delay="$(python3 -c "import json,sys; print(json.load(sys.stdin).get('delay_seconds',10))" <<<"$step_json")"
      while [ "$attempt" -le "$max_retry" ]; do
        if workflow_run_bootstrap_cmd "$cmd" "${extra_args[@]}"; then
          break
        fi
        if [ "$attempt" -lt "$max_retry" ]; then
          log "commande echouee, retry ${attempt}/${max_retry} dans ${delay}s..."
          sleep "$delay"
        else
          workflow_fail "$step_id" "$idx" "$(workflow_step_count)" "commande: ${cmd}"
        fi
        attempt=$((attempt + 1))
      done
      ;;
    confirm)
      if [ "$WF_YES" -eq 1 ] || [ "$WF_DRY_RUN" -eq 1 ]; then
        log "confirm: auto-oui (--yes ou dry-run)"
      else
        local msg
        msg="$(python3 -c "import json,sys; print(json.load(sys.stdin).get('message','Continuer ?'))" <<<"$step_json")"
        printf '%s [o/N] ' "$msg"
        read -r ans
        case "$ans" in
          o|O|y|Y|oui|yes) ;;
          *) die "annule par l'utilisateur" ;;
        esac
      fi
      ;;
    pause)
      local title url
      title="$(python3 -c "import json,sys; print(json.load(sys.stdin).get('title','Pause'))" <<<"$step_json")"
      url="$(python3 -c "
import json,sys
s=json.load(sys.stdin)
print(s.get('url') or (s.get('urls') or {}).get('local') or '')
" <<<"$step_json")"
      [ -z "$url" ] && url="$(workflow_resolve_url)"
      mapfile -t pause_links < <(python3 -c "
import json,sys
for link in json.load(sys.stdin).get('links') or []:
    label=(link.get('label') or '').strip()
    u=(link.get('url') or '').strip()
    if label and u:
        print(label + chr(9) + u)
" <<<"$step_json")
      mapfile -t checklist < <(python3 -c "
import json,sys
for line in json.load(sys.stdin).get('checklist') or []:
    print(line)
" <<<"$step_json")
      if [ "$WF_DRY_RUN" -eq 1 ]; then
        log "[dry-run] pause: ${title}"
        return 0
      fi
      workflow_save_state "$WF_CURRENT_WORKFLOW" "$step_id" "$idx" "$(workflow_step_count)"
      workflow_pause "$title" "$url" "${pause_links[@]}" "${checklist[@]}"
      local va_spec va_retries va_delay
      va_spec="$(python3 -c "
import json,sys
v=json.load(sys.stdin).get('verify_after')
if not v:
    print('')
elif isinstance(v,str):
    print(v)
    print('3 5')
elif isinstance(v,dict):
    print(v.get('id',''))
    print('%s %s' % (v.get('retries',3), v.get('delay_seconds',5)))
elif isinstance(v,list) and v:
    x=v[0]
    if isinstance(x,str):
        print(x)
        print('3 5')
    else:
        print(x.get('id',''))
        print('%s %s' % (x.get('retries',3), x.get('delay_seconds',5)))
" <<<"$step_json")"
      va_retries=3
      va_delay=5
      if [ -n "$va_spec" ]; then
        local va_id
        va_id="$(echo "$va_spec" | head -1)"
        if [ "$(echo "$va_spec" | wc -l)" -ge 2 ]; then
          va_retries="$(echo "$va_spec" | sed -n '2p' | awk '{print $1}')"
          va_delay="$(echo "$va_spec" | sed -n '2p' | awk '{print $2}')"
        fi
        if [ -n "$va_id" ] && ! workflow_run_verifies_retry "$va_id" "$va_retries" "$va_delay"; then
          workflow_fail "$step_id" "$idx" "$(workflow_step_count)" "Le wizard ne semble pas termine (setup_complete)"
        fi
      fi
      ;;
    wait)
      local wait_id timeout elapsed=0 interval
      wait_id="$(python3 -c "import json,sys; print(json.load(sys.stdin).get('wait','stack_running'))" <<<"$step_json")"
      timeout="$(python3 -c "import json,sys; print(json.load(sys.stdin).get('timeout',120))" <<<"$step_json")"
      interval="$(python3 -c "import json,sys; print(json.load(sys.stdin).get('interval',5))" <<<"$step_json")"
      log "attente ${wait_id} (max ${timeout}s, apres wipe/restart compter ~3-6 min)..."
      while [ "$elapsed" -lt "$timeout" ]; do
        if workflow_verify "$wait_id"; then
          log "wait: ${wait_id} OK (${elapsed}s)"
          return 0
        fi
        if [ "$elapsed" -gt 0 ] && [ $((elapsed % 30)) -eq 0 ]; then
          log "toujours en attente ${wait_id}... (${elapsed}/${timeout}s)"
        fi
        sleep "$interval"
        elapsed=$((elapsed + interval))
      done
      workflow_fail "$step_id" "$idx" "$(workflow_step_count)" \
        "timeout wait ${wait_id} — verifier: ./bootstrap status && ./bootstrap logs frontend"
      ;;
    verify)
      local ver
      ver="$(python3 -c "
import json,sys
v=json.load(sys.stdin).get('verify') or []
print(','.join(v) if isinstance(v,list) else v)
" <<<"$step_json")"
      workflow_run_verifies "$ver" || workflow_fail "$step_id" "$idx" "$(workflow_step_count)"
      ;;
    note)
      python3 -c "import json,sys; print(json.load(sys.stdin).get('message',''))" <<<"$step_json" | while read -r line; do
        log "$line"
      done
      ;;
    *)
      workflow_fail "$step_id" "$idx" "$(workflow_step_count)" "type d'etape inconnu: ${step_type}"
      ;;
  esac

  local post_verify
  post_verify="$(python3 -c "
import json,sys
v=json.load(sys.stdin).get('verify') or []
if isinstance(v,list):
    print(','.join(x if isinstance(x,str) else x.get('id','') for x in v))
" <<<"$step_json")"
  if [ -n "$post_verify" ] && [ "$step_type" = "command" ]; then
    local pv_retries=3 pv_delay=5
    if [ "$step_id" = "site_create" ] || [ "$step_id" = "migrate" ]; then
      pv_retries=5
      pv_delay=8
    fi
    if ! workflow_run_verifies_retry "$post_verify" "$pv_retries" "$pv_delay"; then
      workflow_fail "$step_id" "$idx" "$(workflow_step_count)"
    fi
  fi

  workflow_log_file "END ${step_id} OK"
}

workflow_run() {
  local name="$1"
  shift || true
  workflow_parse_cli "$@"
  load_env
  ensure_env_file
  : "${WF_SITE:=${FRAPPE_SITE_NAME_HEADER:-${BOOTSTRAP_SITE:-boutique.local}}}"
  workflow_expand_workflow "$name"

  local total idx=0 started=0
  total="$(workflow_step_count)"

  if [ -n "$WF_FROM_STEP" ]; then
    idx="$(python3 -c "
import json,sys
name=sys.argv[1]
for i,s in enumerate(json.load(sys.stdin)['steps']):
    if s.get('id')==name:
        print(i)
        break
" "$WF_FROM_STEP" <<<"$WF_EXPANDED_JSON")"
    [ -n "$idx" ] || die "etape introuvable: ${WF_FROM_STEP}"
    log "reprise depuis etape: ${WF_FROM_STEP} (index $((idx + 1)))"
  fi

  log "workflow=${name} site=${WF_SITE} etapes=${total} dry_run=${WF_DRY_RUN}"
  python3 -c "
import json,sys
d=json.load(sys.stdin)
for x in d.get('limits') or []:
    print(x)
" <<<"$WF_EXPANDED_JSON" | while read -r lim; do
    log "limite: $lim"
  done

  while [ "$idx" -lt "$total" ]; do
    local step_id
    step_id="$(workflow_step_get id "$idx")"
    if [ "$started" -eq 1 ] || [ -z "$WF_FROM_STEP" ] || [ "$step_id" = "$WF_FROM_STEP" ]; then
      started=1
    fi
    if [ "$started" -eq 1 ]; then
      log "=== etape $((idx + 1))/${total}: ${step_id} ==="
      workflow_execute_step "$idx"
      workflow_save_state "$WF_CURRENT_WORKFLOW" "$step_id" "$idx" "$total"
      if [ -n "$WF_UNTIL_STEP" ] && [ "$step_id" = "$WF_UNTIL_STEP" ]; then
        log "arret --until ${WF_UNTIL_STEP}"
        exit 0
      fi
    fi
    idx=$((idx + 1))
  done
  log "workflow ${name} termine avec succes"
}

workflow_parse_cli() {
  WF_SITE="${BOOTSTRAP_SITE:-}"
  WF_ADMIN_PASSWORD="${BOOTSTRAP_ADMIN_PASSWORD:-admin}"
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --site)
        WF_SITE="${2:-}"
        shift 2
        ;;
      --admin-password)
        WF_ADMIN_PASSWORD="${2:-}"
        shift 2
        ;;
      --yes) WF_YES=1; shift ;;
      --skip-backup) WF_SKIP_BACKUP=1; shift ;;
      --skip-build) WF_SKIP_BUILD=1; shift ;;
      --skip-translations) WF_SKIP_TRANSLATIONS=1; shift ;;
      --with-catalog) WF_WITH_CATALOG=1; shift ;;
      --translation-csv)
        WF_TRANSLATION_CSV="${2:-}"
        shift 2
        ;;
      --from-step)
        WF_FROM_STEP="${2:-}"
        shift 2
        ;;
      --until)
        WF_UNTIL_STEP="${2:-}"
        shift 2
        ;;
      --dry-run) WF_DRY_RUN=1; shift ;;
      --non-interactive) WF_NON_INTERACTIVE=1; shift ;;
      --force-recreate-site) WF_FORCE_RECREATE_SITE=1; shift ;;
      *) die "option workflow inconnue: $1" ;;
    esac
  done
}

workflow_main() {
  ensure_command python3
  workflow_ensure_dirs
  local sub="${1:-}"
  shift || true
  case "$sub" in
    list)
      workflow_list_workflows
      ;;
    describe)
      [ -n "${1:-}" ] || die "usage: ./bootstrap workflow describe <name>"
      load_env
      WF_SITE="${BOOTSTRAP_SITE:-${FRAPPE_SITE_NAME_HEADER:-boutique.local}}"
      workflow_describe "$1"
      ;;
    run)
      [ -n "${1:-}" ] || die "usage: ./bootstrap workflow run <name> [options]"
      workflow_run "$1" "${@:2}"
      ;;
    resume)
      [ -f "$WF_STATE_FILE" ] || die "aucun etat sauvegarde (${WF_STATE_FILE})"
      local wf step next_step
      wf="$(python3 -c "import json; print(json.load(open('$WF_STATE_FILE')).get('workflow',''))")"
      step="$(python3 -c "import json; d=json.load(open('$WF_STATE_FILE')); print(d.get('step_id',''))")"
      WF_SITE="$(python3 -c "import json; print(json.load(open('$WF_STATE_FILE')).get('site','boutique.local'))")"
      workflow_expand_workflow "$wf"
      next_step="$(python3 -c "
import json,sys
state=json.load(open(sys.argv[1]))
data=json.load(sys.stdin)
ids=[s.get('id') for s in data['steps']]
try:
    i=ids.index(state['step_id'])
    print(ids[i+1] if i+1 < len(ids) else '')
except ValueError:
    print('')
" "$WF_STATE_FILE" <<<"$WF_EXPANDED_JSON")"
      [ -n "$next_step" ] || die "aucune etape suivante (workflow deja termine ?)"
      log "resume workflow=${wf} apres pause « ${step} » → etape « ${next_step} »"
      workflow_run "$wf" --from-step "$next_step" "${@}"
      ;;
    verify-only)
      WF_VERIFY_ONLY=1
      [ -n "${1:-}" ] || die "usage: ./bootstrap workflow verify-only <name> [--site ...]"
      workflow_run "$1" "${@:2}"
      ;;
    *)
      cat <<'EOF'
Usage:
  ./bootstrap workflow list
  ./bootstrap workflow describe <name>
  ./bootstrap workflow run <name> [options]
  ./bootstrap workflow resume [options]
  ./bootstrap workflow verify-only <name> [--site ...]

Options run/resume:
  --site, --admin-password, --yes, --skip-backup, --skip-build,
  --skip-translations, --with-catalog, --translation-csv <path>,
  --from-step <id>, --until <id>, --dry-run, --non-interactive, --force-recreate-site
EOF
      ;;
  esac
}
