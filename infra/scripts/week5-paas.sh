#!/usr/bin/env bash
# CSP451 2026F - Week 5 PaaS layer (Seneca CloudLabs lab environment).
# Run from the repository root with:  bash infra/scripts/week5-paas.sh   (bash, not zsh)
# First run:  INTEGRATE_FUNCTION=no bash infra/scripts/week5-paas.sh
# After the first decisionWorker call (F7), run it again with no override (INTEGRATE_FUNCTION defaults to "yes").
# Re-runnable: every create is guarded by an existence check.
# Prints no secret: commands that can return one use -o none or a --query that excludes it.
# The slot exercise is a manual, timed sequence and is not part of this script.
if [ -z "${BASH_VERSION:-}" ]; then
  echo "ERROR: run this script with bash: bash infra/scripts/week5-paas.sh" >&2
  exit 1
fi
set -euo pipefail

# Git Bash on Windows safety (no effect on Linux, macOS or WSL): stop Git Bash rewriting
# arguments that start with a slash, and strip the carriage returns the Windows Azure CLI adds.
case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*)
    export MSYS_NO_PATHCONV=1
    az() { command az "$@" | tr -d '\r'; return "${PIPESTATUS[0]}"; }
    winpath() { cygpath -m "$1"; }
    ;;
  *)
    winpath() { printf '%s' "$1"; }
    ;;
esac

# pack <folder> <zipfile>: zip with the zip command, or with Windows bsdtar when zip is missing.
pack() {
  local src out
  src="$(cd "$1" && pwd)"; out="$(cd "$(dirname "$2")" && pwd)/$(basename "$2")"; rm -f "$out"
  if command -v zip >/dev/null 2>&1; then
    (cd "$src" && zip -qr "$out" . -x ".git/*" "*.env" "local.settings.json" "node_modules/.cache/*")
  else
    (cd "$src" && /c/Windows/System32/tar.exe -a -cf "$(winpath "$out")" --exclude=.git --exclude=local.settings.json --exclude="*.env" *)
  fi
}

TEAM="group6"                        # registered team name, lowercase
STUDENT_ID="180346215"               # full Seneca student ID
LAB_RG_OVERRIDE=""          # set only if the detection below does not find exactly one group
DEPLOY_API="yes"            # "no" skips the zip deployment of ./api
BUILD_FUNCTION="yes"        # "no" skips the Function app stage
INTEGRATE_FUNCTION="${INTEGRATE_FUNCTION:-yes}"   # first run: INTEGRATE_FUNCTION=no; run again with the default "yes" after the first decisionWorker call (F7)
LOC="canadacentral"

if [ -n "$LAB_RG_OVERRIDE" ]; then
  RG="$LAB_RG_OVERRIDE"
else
  RG=$(az group list --query "[?starts_with(name,'Student-RG-')].name" -o tsv)
  if [ "$(printf '%s\n' "$RG" | grep -c .)" -ne 1 ]; then
    echo "ERROR: expected exactly one Student-RG-* group. Check az account show, or set LAB_RG_OVERRIDE." >&2
    exit 1
  fi
fi

SID4="${STUDENT_ID: -4}"
T7=$(printf '%s' "$TEAM" | tr 'A-Z' 'a-z' | tr -cd 'a-z0-9' | cut -c1-7)
VNET="vnet-csp451-${TEAM}-dev"
PLAN="plan-loanrisk-${TEAM}"
APP="app-loanrisk-${TEAM}-${SID4}"
FUNC="func-loanrisk-${TEAM}-${SID4}"
STG="stfunc${T7}${SID4}"
BUREAU_URL="http://bureau.loanrisk.internal:8080"
TAGS="course=CSP451 term=2026F team=${TEAM} owner=${STUDENT_ID} env=dev"

# exists <resource type> <name>: true when the group already holds that resource.
exists() {
  [ -n "$(az resource list -g "$RG" --location "" --resource-type "$1" --name "$2" --query "[].id" -o tsv)" ]
}

echo "==> Lab group ${RG}; plan ${PLAN}; web app ${APP}; Function app ${FUNC}; storage ${STG}"

DELEGATION=$(az network vnet subnet show -g "$RG" --vnet-name "$VNET" -n snet-app \
  --query "delegations[0].serviceName" -o tsv)
if [ "$DELEGATION" != "Microsoft.Web/serverFarms" ]; then
  echo "ERROR: ${VNET}/snet-app is missing or not delegated to Microsoft.Web/serverFarms. Finish CP4 first." >&2
  exit 1
fi

echo "==> 1. App Service plan (Linux B1) and web app (NODE:22-lts)"
exists Microsoft.Web/serverFarms "$PLAN" || \
  az appservice plan create -g "$RG" -n "$PLAN" -l "$LOC" --is-linux --sku B1 --tags $TAGS -o none
exists Microsoft.Web/sites "$APP" || \
  az webapp create -g "$RG" --plan "$PLAN" -n "$APP" --runtime "NODE:22-lts" --tags $TAGS -o none

echo "==> 2. Web app hardening, identity and settings"
az webapp update -g "$RG" -n "$APP" --https-only true -o none
az webapp config set -g "$RG" -n "$APP" \
  --always-on true --min-tls-version 1.2 --ftps-state Disabled --http20-enabled true -o none
az webapp config set -g "$RG" -n "$APP" --generic-configurations '{"healthCheckPath": "/health"}' -o none
az webapp identity assign -g "$RG" -n "$APP" -o none
az webapp config appsettings set -g "$RG" -n "$APP" -o none --settings \
  BUREAU_BASE_URL="$BUREAU_URL" RULES_VERSION="1.0.0" WEBSITE_RUN_FROM_PACKAGE="1"

if [ "$DEPLOY_API" = "yes" ]; then
  echo "==> 3. Zip deployment of ./api"
  [ -f api/package.json ] || { echo "ERROR: ./api/package.json not found; run from the repository root." >&2; exit 1; }
  if [ -f api/package-lock.json ]; then (cd api && npm ci --omit=dev); fi
  pack api api.zip
  az webapp deploy -g "$RG" -n "$APP" --src-path "$(winpath api.zip)" --type zip --async false -o none
fi

echo "==> 4. Web app VNet integration into snet-app, route all"
WEBAPP_NEW_INTEGRATION="no"
if [ -z "$(az webapp vnet-integration list -g "$RG" -n "$APP" --query "[?name=='snet-app'].name" -o tsv)" ]; then
  az webapp vnet-integration add -g "$RG" -n "$APP" --vnet "$VNET" --subnet snet-app -o none
  WEBAPP_NEW_INTEGRATION="yes"
fi
az webapp config set -g "$RG" -n "$APP" --generic-configurations '{"vnetRouteAllEnabled": true}' -o none
if [ "$WEBAPP_NEW_INTEGRATION" = "yes" ]; then
  # A running app joins a new integration only after a restart (Stage 4, step 4).
  az webapp restart -g "$RG" -n "$APP"
fi

if [ "$BUILD_FUNCTION" = "yes" ]; then
  echo "==> 5. Storage account and Function app on ${PLAN}"
  exists Microsoft.Storage/storageAccounts "$STG" || \
    az storage account create -g "$RG" -n "$STG" -l "$LOC" --sku Standard_LRS --kind StorageV2 \
      --min-tls-version TLS1_2 --allow-blob-public-access false --tags $TAGS -o none
  exists Microsoft.Web/sites "$FUNC" || \
    az functionapp create -g "$RG" -n "$FUNC" --plan "$PLAN" --storage-account "$STG" \
      --runtime node --runtime-version 22 --functions-version 4 --disable-app-insights --tags $TAGS -o none
  az functionapp update -g "$RG" -n "$FUNC" --set httpsOnly=true -o none
  az functionapp config set -g "$RG" -n "$FUNC" \
    --always-on true --min-tls-version 1.2 --ftps-state Disabled -o none
  az functionapp identity assign -g "$RG" -n "$FUNC" -o none
  az functionapp config appsettings set -g "$RG" -n "$FUNC" -o none --settings \
    RULES_VERSION="1.0.0" BUREAU_BASE_URL="$BUREAU_URL"
  if [ "$INTEGRATE_FUNCTION" = "yes" ]; then
    echo "==> 6. Function app VNet integration into snet-app, route all"
    if [ -z "$(az functionapp vnet-integration list -g "$RG" -n "$FUNC" --query "[?name=='snet-app'].name" -o tsv)" ]; then
      az functionapp vnet-integration add -g "$RG" -n "$FUNC" --vnet "$VNET" --subnet snet-app -o none
    fi
    az functionapp config set -g "$RG" -n "$FUNC" --generic-configurations '{"vnetRouteAllEnabled": true}' -o none
  fi
fi

echo "==> Summary (no secret values)"
az appservice plan show -g "$RG" -n "$PLAN" --query "{plan:name, sku:sku.name, linux:properties.reserved}" -o table
az webapp show -g "$RG" -n "$APP" --query "{app:name, https:httpsOnly, host:defaultHostName}" -o table
az webapp vnet-integration list -g "$RG" -n "$APP" --query "[].{app_integration:name}" -o table
if [ "$BUILD_FUNCTION" = "yes" ]; then
  az functionapp show -g "$RG" -n "$FUNC" --query "{func:name, state:state, https:httpsOnly}" -o table
  az functionapp vnet-integration list -g "$RG" -n "$FUNC" --query "[].{func_integration:name}" -o table
fi
az resource list -g "$RG" --location "" --query "[?tags.course!=null].{name:name, course:tags.course, term:tags.term, team:tags.team, owner:tags.owner, env:tags.env}" -o table