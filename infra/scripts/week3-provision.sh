#!/usr/bin/env bash
# CSP451 2026F - Week 3 provisioning script (Seneca CloudLabs lab environment)
# Tags your assigned lab resource group, then creates an action group, a budget,
# and the mock bureau VM inside it. Safe to re-run: existing resources are left
# in place and the settings that can drift are applied again.
# Run with:  bash infra/scripts/week3-provision.sh   (never with zsh)

if [ -z "${BASH_VERSION:-}" ]; then
  echo "ERROR: run this script with bash: bash infra/scripts/week3-provision.sh" >&2
  exit 1
fi

set -euo pipefail

# Git Bash on Windows safety (no effect on Linux, macOS or WSL):
# stop Git Bash rewriting arguments that start with a slash, and strip the
# carriage returns the Windows Azure CLI adds to its output.
case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*)
    export MSYS_NO_PATHCONV=1
    az() { command az "$@" | tr -d '\r'; return "${PIPESTATUS[0]}"; }
    ;;
esac

# ---------------------------------------------------------------------------
# 1. Edit these values only.
# ---------------------------------------------------------------------------
TEAM="group6"                        # your team name, lowercase
STUDENT_ID="180346215"               # your Seneca student ID
ALERT_EMAIL="<your-seneca-email>"    # receives budget and auto-shutdown notifications
LAB_RG_OVERRIDE=""                   # leave empty to detect Student-RG-<labID> automatically

if [[ "${TEAM}${STUDENT_ID}${ALERT_EMAIL}" == *"<"* ]]; then
  echo "ERROR: replace <team>, <studentID> and <your-seneca-email> in part 1 first." >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# 2. Derived values. Do not edit.
# ---------------------------------------------------------------------------
LOCATION="canadacentral"
ENVIRONMENT="dev"
VM="vm-bureau-${TEAM}"
ACTION_GROUP="ag-csp451-${TEAM}"
BUDGET="budget-csp451-${TEAM}"
ADMIN_USER="azureuser"
VM_SIZE="Standard_B1s"               # must be on the lab's allowed-size list
VM_IMAGE="Ubuntu2204"
DISK_SKU="StandardSSD_LRS"           # lab policy allows StandardSSD_LRS or Standard_LRS only
BUDGET_AMOUNT="20"                   # in the lab subscription's billing currency
SHUTDOWN_TIME="2300"                 # HHmm, local time in SHUTDOWN_TZ
SHUTDOWN_TZ="Eastern Standard Time"  # Windows time zone ID, follows EST and EDT
TAGS=(course=CSP451 term=2026F "team=${TEAM}" "owner=${STUDENT_ID}" "env=${ENVIRONMENT}")
BICEP_FILE="$(cd "$(dirname "$0")/../bicep" && pwd)/budget.bicep"
# Windows az needs a C:/... style path, not /c/...
command -v cygpath >/dev/null 2>&1 && BICEP_FILE="$(cygpath -m "${BICEP_FILE}")"

echo "==> Subscription and signed-in account"
az account show --query "{subscription:name, subscriptionId:id, user:user.name}" -o table

# ---------------------------------------------------------------------------
# 3. Lab resource group: detect it, check it, make it the default
# ---------------------------------------------------------------------------
if [[ -n "${LAB_RG_OVERRIDE}" ]]; then
  RG="${LAB_RG_OVERRIDE}"
else
  RG_LIST=$(az group list --query "[?starts_with(name,'Student-RG-')].name" -o tsv)
  RG_COUNT=$(printf '%s\n' "${RG_LIST}" | grep -c . || true)
  if [[ "${RG_COUNT}" -ne 1 ]]; then
    echo "ERROR: expected exactly one Student-RG-* group, found ${RG_COUNT}." >&2
    [[ -n "${RG_LIST}" ]] && echo "${RG_LIST}" >&2
    echo "Check that az account show names the lab account and the lab subscription," >&2
    echo "or set LAB_RG_OVERRIDE at the top of this script." >&2
    exit 1
  fi
  RG="${RG_LIST}"
fi

if ! az group show --name "${RG}" --output none 2>/dev/null; then
  echo "ERROR: resource group ${RG} not found in this subscription." >&2
  exit 1
fi
echo "==> Using lab resource group ${RG}"
az configure --defaults location="${LOCATION}" group="${RG}"

# ---------------------------------------------------------------------------
# 4. Merge the five course tags onto the lab group (lab tags are kept)
# ---------------------------------------------------------------------------
echo "==> Merging course tags onto ${RG}"
az group update \
  --name "${RG}" \
  --set tags.course=CSP451 tags.term=2026F "tags.team=${TEAM}" \
        "tags.owner=${STUDENT_ID}" "tags.env=${ENVIRONMENT}" \
  --output none

# ---------------------------------------------------------------------------
# 5. Action group for budget notifications
# ---------------------------------------------------------------------------
if az monitor action-group show --name "${ACTION_GROUP}" --resource-group "${RG}" --output none 2>/dev/null; then
  echo "==> Action group ${ACTION_GROUP} already exists, left in place"
else
  echo "==> Creating action group ${ACTION_GROUP}"
  # Action groups are global resources: canadacentral (the CLI default set above) is rejected.
  az monitor action-group create \
    --name "${ACTION_GROUP}" \
    --resource-group "${RG}" \
    --location global \
    --short-name "csp451" \
    --action email budgetOwner "${ALERT_EMAIL}" \
    --tags "${TAGS[@]}" \
    --output none
fi

ACTION_GROUP_ID=$(az monitor action-group show \
  --name "${ACTION_GROUP}" --resource-group "${RG}" --query id -o tsv)
echo "    Action group ID: ${ACTION_GROUP_ID}"

# ---------------------------------------------------------------------------
# 6. Budget with 50 / 80 / 100 percent alerts, deployed from Bicep
# ---------------------------------------------------------------------------
if az consumption budget show --budget-name "${BUDGET}" --resource-group "${RG}" --output none 2>/dev/null; then
  echo "==> Budget ${BUDGET} already exists, left in place"
else
  echo "==> Deploying budget ${BUDGET}"
  az deployment group create \
    --resource-group "${RG}" \
    --name "budget-deploy" \
    --template-file "${BICEP_FILE}" \
    --parameters budgetName="${BUDGET}" \
                 amount="${BUDGET_AMOUNT}" \
                 contactEmails="['${ALERT_EMAIL}']" \
                 actionGroupId="${ACTION_GROUP_ID}" \
    --output table
fi

# ---------------------------------------------------------------------------
# 7. Mock bureau virtual machine (joins the existing lab VNet: five new resources)
# ---------------------------------------------------------------------------
if az vm show --resource-group "${RG}" --name "${VM}" --output none 2>/dev/null; then
  echo "==> Virtual machine ${VM} already exists, left in place"
else
  echo "==> Creating virtual machine ${VM}"
  az vm create \
    --resource-group "${RG}" \
    --name "${VM}" \
    --location "${LOCATION}" \
    --image "${VM_IMAGE}" \
    --size "${VM_SIZE}" \
    --admin-username "${ADMIN_USER}" \
    --generate-ssh-keys \
    --public-ip-sku Standard \
    --nsg-rule SSH \
    --os-disk-size-gb 30 \
    --storage-sku "${DISK_SKU}" \
    --tags "${TAGS[@]}" \
    --output table
fi

# ---------------------------------------------------------------------------
# 8. Restrict SSH to this machine's public address only
# ---------------------------------------------------------------------------
echo "==> Restricting SSH to your current public IP"
MY_IP=$(curl -fsS https://api.ipify.org)
if [[ ! "${MY_IP}" =~ ^[0-9]{1,3}(\.[0-9]{1,3}){3}$ ]]; then
  echo "ERROR: could not detect your public IPv4 address (got '${MY_IP}')." >&2
  exit 1
fi
echo "    Detected public IP: ${MY_IP}"

az network nsg rule update \
  --resource-group "${RG}" \
  --nsg-name "${VM}NSG" \
  --name "default-allow-ssh" \
  --source-address-prefixes "${MY_IP}/32" \
  --priority 300 \
  --description "SSH from the student workstation only" \
  --output none

# ---------------------------------------------------------------------------
# 9. Auto-shutdown, mandatory in this course
#    --time is interpreted as UTC, so the time zone is set in a second step.
# ---------------------------------------------------------------------------
echo "==> Enabling auto-shutdown at ${SHUTDOWN_TIME} ${SHUTDOWN_TZ}"
az vm auto-shutdown \
  --resource-group "${RG}" \
  --name "${VM}" \
  --time "${SHUTDOWN_TIME}" \
  --email "${ALERT_EMAIL}" \
  --output none

az resource update \
  --resource-group "${RG}" \
  --name "shutdown-computevm-${VM}" \
  --resource-type "Microsoft.DevTestLab/schedules" \
  --set properties.timeZoneId="${SHUTDOWN_TZ}" \
  --output none

# az vm auto-shutdown has no --tags option, so tag the schedule resource here.
# Proven in the lab run; if it fails for you, keep the error for your write-up.
if ! az resource tag \
  --resource-group "${RG}" \
  --name "shutdown-computevm-${VM}" \
  --resource-type "Microsoft.DevTestLab/schedules" \
  --is-incremental \
  --tags "${TAGS[@]}" \
  --output none; then
  echo "WARNING: could not tag shutdown-computevm-${VM}. Keep this error for your write-up." >&2
fi

# ---------------------------------------------------------------------------
# 10. Report
# ---------------------------------------------------------------------------
PUBLIC_IP=$(az vm show --resource-group "${RG}" --name "${VM}" -d --query publicIps -o tsv)
PRIVATE_IP=$(az vm show --resource-group "${RG}" --name "${VM}" -d --query privateIps -o tsv)
POWER=$(az vm show --resource-group "${RG}" --name "${VM}" -d --query powerState -o tsv)
SUBNET_ID=$(az network nic show --resource-group "${RG}" --name "${VM}VMNic" \
  --query "ipConfigurations[0].subnet.id" -o tsv)
VNET_NAME="${SUBNET_ID#*/virtualNetworks/}"
VNET_NAME="${VNET_NAME%%/*}"
SHUTDOWN=$(az resource show --resource-group "${RG}" --name "shutdown-computevm-${VM}" \
  --resource-type "Microsoft.DevTestLab/schedules" \
  --query "join(' ', [properties.status, properties.dailyRecurrence.time, properties.timeZoneId])" -o tsv)

cat <<EOF

==> Done.
    Resource group : ${RG}
    VM             : ${VM} (${VM_SIZE}, ${VM_IMAGE}, ${DISK_SKU}), ${POWER}
    Virtual network: ${VNET_NAME} (lab VNet, not created by this script)
    Public IP      : ${PUBLIC_IP}
    Private IP     : ${PRIVATE_IP}
    SSH allowed    : ${MY_IP}/32 only
    Connect with   : ssh ${ADMIN_USER}@${PUBLIC_IP}
    Auto-shutdown  : ${SHUTDOWN}

EOF

echo "==> Resources in ${RG}"
az resource list --resource-group "${RG}" --location "" --query "[].{Name:name, Type:type}" -o table
