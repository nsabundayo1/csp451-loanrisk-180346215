#!/usr/bin/env bash
# CSP451 2026F - Week 4 network script (Seneca CloudLabs lab environment)
# Builds the course VNet, three subnets, the ASG, both NSGs, the private DNS zone and
# the private bureau VM in your assigned lab group, then installs the mock bureau
# through az vm run-command. Run it from the root of your repository clone with:
#   bash infra/scripts/week4-network.sh        (bash, not zsh)
# Safe to re-run: existing resources are left in place, and the settings that can
# drift are applied again. It never creates or deletes a resource group, a Bastion
# host or a flow log.
if [ -z "${BASH_VERSION:-}" ]; then
  echo "ERROR: run this script with bash: bash infra/scripts/week4-network.sh" >&2
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
# ---------------------------------------------------------------------------
# 1. Edit these values only.
# ---------------------------------------------------------------------------
TEAM="group6"                        # your registered team name, lowercase
STUDENT_ID="180346215"               # your Seneca student ID
ALERT_EMAIL="nsabundayo@myseneca.ca" # receives the auto-shutdown notice
LAB_RG_OVERRIDE=""                   # leave empty to detect Student-RG-<labID> automatically
NODE_MAJOR="22"                      # Node.js 22 LTS; the only accepted fallback is 24, never 20
FILE_METHOD="run-command"            # "run-command", or "cloud-init" only for the fallback
# ---------------------------------------------------------------------------
# 2. Derived values (course naming table). Do not edit.
# ---------------------------------------------------------------------------
LOCATION="canadacentral"
ENVIRONMENT="dev"
VNET="vnet-csp451-${TEAM}-${ENVIRONMENT}"
VNET_PREFIX="10.20.0.0/16"
SNET_BUREAU_PREFIX="10.20.1.0/24"
SNET_APP_PREFIX="10.20.2.0/24"
SNET_DATA_PREFIX="10.20.3.0/24"
ASG="asg-bureau-${TEAM}"
NSG_BUREAU="nsg-bureau-${TEAM}"
NSG_APP="nsg-app-${TEAM}"
VM="vm-bureau-${TEAM}"
NIC="${VM}VMNic"
ADMIN_USER="azureuser"
VM_SIZE="Standard_B1s"               # on the lab's allowed-size list
VM_IMAGE="Ubuntu2204"
DISK_SKU="StandardSSD_LRS"           # the lab allows StandardSSD_LRS or Standard_LRS only
BUREAU_PORT="8080"
DNS_ZONE="loanrisk.internal"
DNS_LINK="link-bureau-${TEAM}"
SHUTDOWN_TIME="2300"
SHUTDOWN_TZ="Eastern Standard Time"
TAGS=(course=CSP451 term=2026F "team=${TEAM}" "owner=${STUDENT_ID}" "env=${ENVIRONMENT}")
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUREAU_SRC="${SCRIPT_DIR}/../../mock-bureau"
BUREAU_FILES=(server.js package.json package-lock.json)
WORK_DIR="$(mktemp -d)"
trap 'rm -rf "${WORK_DIR}"' EXIT
if [[ ! "${TEAM}" =~ ^[a-z0-9-]+$ || ! "${STUDENT_ID}" =~ ^[0-9]+$ || "${ALERT_EMAIL}" != *@* ]]; then
  echo "ERROR: set TEAM, STUDENT_ID and ALERT_EMAIL in section 1 first." >&2
  exit 1
fi
for f in "${BUREAU_FILES[@]}"; do
  if [[ ! -s "${BUREAU_SRC}/${f}" ]]; then
    echo "ERROR: ${BUREAU_SRC}/${f} not found. Keep the script in infra/scripts/ of your repository." >&2
    exit 1
  fi
done
# gzip a file, then base64 it on one line (same result with the macOS and the Linux base64).
b64gz() { tr -d '\r' < "$1" | gzip -9 -c | base64 | tr -d '\n'; }
# ---------------------------------------------------------------------------
# 3. Lab resource group: detect it, check it, make it the default
# ---------------------------------------------------------------------------
echo "==> Subscription and signed-in account"
az account show --query "{subscription:name, subscriptionId:id, user:user.name}" -o table
if [[ -n "${LAB_RG_OVERRIDE}" ]]; then
  RG="${LAB_RG_OVERRIDE}"
else
  RG_LIST=$(az group list --query "[?starts_with(name,'Student-RG-')].name" -o tsv)
  RG_COUNT=$(printf '%s\n' "${RG_LIST}" | grep -c . || true)
  if [[ "${RG_COUNT}" -ne 1 ]]; then
    echo "ERROR: expected exactly one Student-RG-* group, found ${RG_COUNT}." >&2
    echo "Check az account show, or set LAB_RG_OVERRIDE in section 1." >&2
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
# 4. Course virtual network and its three subnets (no AzureBastionSubnet)
# ---------------------------------------------------------------------------
if az network vnet show -g "${RG}" -n "${VNET}" -o none 2>/dev/null; then
  echo "==> VNet ${VNET} already exists, left in place"
else
  echo "==> Creating VNet ${VNET} (${VNET_PREFIX})"
  az network vnet create -g "${RG}" -n "${VNET}" -l "${LOCATION}" \
    --address-prefixes "${VNET_PREFIX}" --tags "${TAGS[@]}" -o none
fi
# ensure_subnet <name> <prefix> [extra arguments for az network vnet subnet create]
ensure_subnet() {
  local name="$1" prefix="$2"
  shift 2
  if az network vnet subnet show -g "${RG}" --vnet-name "${VNET}" -n "${name}" -o none 2>/dev/null; then
    echo "==> Subnet ${name} already exists, left in place"
  else
    echo "==> Creating subnet ${name} (${prefix})"
    az network vnet subnet create -g "${RG}" --vnet-name "${VNET}" -n "${name}" \
      --address-prefixes "${prefix}" "$@" -o none
  fi
}
# Bureau subnet: default outbound access on, so the private VM can reach NodeSource and npm.
ensure_subnet snet-bureau "${SNET_BUREAU_PREFIX}" --default-outbound-access true
# App subnet: delegated to App Service (web app and Function app VNet integration, Week 5).
ensure_subnet snet-app "${SNET_APP_PREFIX}" --delegations Microsoft.Web/serverFarms
# Data subnet: delegated to PostgreSQL Flexible Server (Week 9).
ensure_subnet snet-data "${SNET_DATA_PREFIX}" --delegations Microsoft.DBforPostgreSQL/flexibleServers
# ---------------------------------------------------------------------------
# 5. Application security group for the bureau VM's network interface
# ---------------------------------------------------------------------------
if az network asg show -g "${RG}" -n "${ASG}" -o none 2>/dev/null; then
  echo "==> ASG ${ASG} already exists, left in place"
else
  echo "==> Creating ASG ${ASG}"
  az network asg create -g "${RG}" -n "${ASG}" -l "${LOCATION}" --tags "${TAGS[@]}" -o none
fi
# ---------------------------------------------------------------------------
# 6. Network security groups, their rules, and the subnet associations
# ---------------------------------------------------------------------------
ensure_nsg() {
  if az network nsg show -g "${RG}" -n "$1" -o none 2>/dev/null; then
    echo "==> NSG $1 already exists, left in place"
  else
    echo "==> Creating NSG $1"
    az network nsg create -g "${RG}" -n "$1" -l "${LOCATION}" --tags "${TAGS[@]}" -o none
  fi
}
# ensure_rule <nsg> <rule name> <arguments for az network nsg rule create>
ensure_rule() {
  local nsg="$1" name="$2"
  shift 2
  if az network nsg rule show -g "${RG}" --nsg-name "${nsg}" -n "${name}" -o none 2>/dev/null; then
    echo "    rule ${name} already exists in ${nsg}, left in place"
  else
    echo "    creating rule ${name} in ${nsg}"
    az network nsg rule create -g "${RG}" --nsg-name "${nsg}" -n "${name}" "$@" -o none
  fi
}
ensure_nsg "${NSG_BUREAU}"
# 100: the only permitted application path into the bureau tier.
ensure_rule "${NSG_BUREAU}" Allow-App-Subnet-To-Bureau-Service \
  --priority 100 --direction Inbound --access Allow --protocol Tcp \
  --source-address-prefixes "${SNET_APP_PREFIX}" --source-port-ranges '*' \
  --destination-asgs "${ASG}" --destination-port-ranges "${BUREAU_PORT}" \
  --description "Only the app subnet may call the mock bureau service."
# 4000: overrides the default AllowVnetInBound rule at 65000. There is no SSH rule.
ensure_rule "${NSG_BUREAU}" Deny-All-Other-Inbound \
  --priority 4000 --direction Inbound --access Deny --protocol '*' \
  --source-address-prefixes '*' --source-port-ranges '*' \
  --destination-address-prefixes '*' --destination-port-ranges '*' \
  --description "Overrides AllowVnetInBound so no other source reaches the bureau."
ensure_nsg "${NSG_APP}"
# 100: the app tier may open TCP 8080 to the bureau subnet.
ensure_rule "${NSG_APP}" Allow-App-To-Bureau-Service \
  --priority 100 --direction Outbound --access Allow --protocol Tcp \
  --source-address-prefixes "${SNET_APP_PREFIX}" --source-port-ranges '*' \
  --destination-address-prefixes "${SNET_BUREAU_PREFIX}" --destination-port-ranges "${BUREAU_PORT}" \
  --description "The only permitted path from the app tier to the bureau tier."
# 300: and nothing else on the bureau subnet (no SSH, no other port).
ensure_rule "${NSG_APP}" Deny-Bureau-Subnet-Other-Ports \
  --priority 300 --direction Outbound --access Deny --protocol '*' \
  --source-address-prefixes '*' --source-port-ranges '*' \
  --destination-address-prefixes "${SNET_BUREAU_PREFIX}" --destination-port-ranges '*' \
  --description "Stops the app tier opening any other port on the bureau subnet."
# Attach at subnet level only (re-applied on every run).
echo "==> Associating ${NSG_BUREAU} with snet-bureau"
az network vnet subnet update -g "${RG}" --vnet-name "${VNET}" -n snet-bureau \
  --network-security-group "${NSG_BUREAU}" -o none
echo "==> Associating ${NSG_APP} with snet-app"
if ! az network vnet subnet update -g "${RG}" --vnet-name "${VNET}" -n snet-app \
     --network-security-group "${NSG_APP}" -o none; then
  echo "WARNING: Azure refused to attach ${NSG_APP} to the delegated subnet snet-app." >&2
  echo "         Capture the error above for S5. The NSG stays in place with both rules." >&2
fi
# ---------------------------------------------------------------------------
# 7. The private bureau VM: no public IP, no NIC-level NSG, member of the ASG
# ---------------------------------------------------------------------------
# Fallback only (FILE_METHOD="cloud-init"): the three starter-kit files travel as
# custom data and cloud-init writes them to /var/lib/mock-bureau-src at first boot.
CLOUD_INIT_FILE="${WORK_DIR}/cloud-init-bureau.yaml"
if [[ "${FILE_METHOD}" == "cloud-init" ]]; then
  {
    echo "#cloud-config"
    echo "write_files:"
    for f in "${BUREAU_FILES[@]}"; do
      echo "  - path: /var/lib/mock-bureau-src/${f}"
      echo "    encoding: gz+b64"
      echo "    permissions: '0644'"
      echo "    content: $(b64gz "${BUREAU_SRC}/${f}")"
    done
  } > "${CLOUD_INIT_FILE}"
fi
if az vm show -g "${RG}" -n "${VM}" -o none 2>/dev/null; then
  echo "==> VM ${VM} already exists, left in place"
else
  echo "==> Creating private VM ${VM} in ${VNET}/snet-bureau (about a minute)"
  # Two VNets are now in the group, so --vnet-name and --subnet are required.
  # --public-ip-address "" gives no public IP; --nsg "" gives no NIC-level NSG.
  # Azure still needs an SSH key for a Linux VM, but nothing in this design uses it.
  VM_ARGS=(
    --resource-group "${RG}" --name "${VM}" --location "${LOCATION}"
    --image "${VM_IMAGE}" --size "${VM_SIZE}"
    --admin-username "${ADMIN_USER}" --generate-ssh-keys
    --vnet-name "${VNET}" --subnet snet-bureau
    --public-ip-address "" --nsg "" --asgs "${ASG}"
    --os-disk-size-gb 30 --storage-sku "${DISK_SKU}"
    --tags "${TAGS[@]}"
  )
  if [[ "${FILE_METHOD}" == "cloud-init" ]]; then
    VM_ARGS+=(--custom-data "$(winpath "${CLOUD_INIT_FILE}")")
  fi
  az vm create "${VM_ARGS[@]}" -o table
fi
# Re-applied on every run: the NIC is a member of the bureau ASG.
IPCFG=$(az network nic ip-config list -g "${RG}" --nic-name "${NIC}" --query "[0].name" -o tsv)
az network nic ip-config update -g "${RG}" --nic-name "${NIC}" -n "${IPCFG}" \
  --application-security-groups "${ASG}" -o none
# Guard rails: stop if the VM has a public IP or a NIC-level NSG.
PUBLIC_IP=$(az vm show -d -g "${RG}" -n "${VM}" --query publicIps -o tsv)
NIC_NSG=$(az network nic show -g "${RG}" -n "${NIC}" --query "networkSecurityGroup.id" -o tsv)
if [[ -n "${PUBLIC_IP}" || -n "${NIC_NSG}" ]]; then
  echo "ERROR: ${VM} has a public IP (${PUBLIC_IP:-none}) or a NIC-level NSG (${NIC_NSG:-none})." >&2
  echo "       Remove the VM (see Troubleshooting) and run this script again." >&2
  exit 1
fi
# ---------------------------------------------------------------------------
# 8. Auto-shutdown at 23:00 Toronto time (the Week 3 schedule went with the Week 3 VM)
# ---------------------------------------------------------------------------
echo "==> Auto-shutdown at ${SHUTDOWN_TIME} ${SHUTDOWN_TZ}"
az vm auto-shutdown -g "${RG}" -n "${VM}" --time "${SHUTDOWN_TIME}" --email "${ALERT_EMAIL}" -o none
# --time alone is read as UTC, so set the schedule's time zone explicitly.
az resource update -g "${RG}" -n "shutdown-computevm-${VM}" \
  --resource-type Microsoft.DevTestLab/schedules \
  --set properties.timeZoneId="${SHUTDOWN_TZ}" -o none
# az vm auto-shutdown has no --tags option; az resource tag works on the schedule (verified in the lab).
if ! az resource tag -g "${RG}" -n "shutdown-computevm-${VM}" \
     --resource-type Microsoft.DevTestLab/schedules --is-incremental \
     --tags "${TAGS[@]}" -o none; then
  echo "WARNING: could not tag shutdown-computevm-${VM}; name it in your untagged-item note (C1)." >&2
fi
# ---------------------------------------------------------------------------
# 9. Private DNS: zone, link to the course VNet, and the bureau A record
# ---------------------------------------------------------------------------
BUREAU_IP=$(az vm list-ip-addresses -g "${RG}" -n "${VM}" \
  --query "[0].virtualMachine.network.privateIpAddresses[0]" -o tsv)
echo "==> Bureau private IP: ${BUREAU_IP}"
if az network private-dns zone show -g "${RG}" -n "${DNS_ZONE}" -o none 2>/dev/null; then
  echo "==> Zone ${DNS_ZONE} already exists, left in place"
else
  echo "==> Creating private DNS zone ${DNS_ZONE} (about 30 seconds)"
  az network private-dns zone create -g "${RG}" -n "${DNS_ZONE}" --tags "${TAGS[@]}" -o none
fi
if az network private-dns link vnet show -g "${RG}" -z "${DNS_ZONE}" -n "${DNS_LINK}" -o none 2>/dev/null; then
  echo "==> Link ${DNS_LINK} already exists, left in place"
else
  # Registration disabled: you manage the records yourself.
  echo "==> Linking ${DNS_ZONE} to ${VNET} as ${DNS_LINK} (about 30 seconds)"
  az network private-dns link vnet create -g "${RG}" -z "${DNS_ZONE}" -n "${DNS_LINK}" \
    --virtual-network "${VNET}" --registration-enabled false --tags "${TAGS[@]}" -o none
fi
# The A record is the only place the private IP is written. Keep it in step with the VM.
CURRENT_IPS=$(az network private-dns record-set a show -g "${RG}" -z "${DNS_ZONE}" -n bureau \
  --query "aRecords[].ipv4Address" -o tsv 2>/dev/null || true)
for ip in ${CURRENT_IPS}; do
  if [[ "${ip}" != "${BUREAU_IP}" ]]; then
    echo "==> Removing stale address ${ip} from bureau.${DNS_ZONE}"
    az network private-dns record-set a remove-record -g "${RG}" -z "${DNS_ZONE}" \
      --record-set-name bureau --ipv4-address "${ip}" --keep-empty-record-set -o none
  fi
done
if ! printf '%s\n' "${CURRENT_IPS}" | grep -qx "${BUREAU_IP}"; then
  echo "==> Adding bureau.${DNS_ZONE} -> ${BUREAU_IP}"
  az network private-dns record-set a add-record -g "${RG}" -z "${DNS_ZONE}" \
    --record-set-name bureau --ipv4-address "${BUREAU_IP}" -o none
fi
az network private-dns record-set a show -g "${RG}" -z "${DNS_ZONE}" -n bureau \
  --query "{fqdn:fqdn, addresses:aRecords[].ipv4Address}" -o json
# ---------------------------------------------------------------------------
# 10. Install the mock bureau and ufw on the VM through run-command (no SSH)
# ---------------------------------------------------------------------------
# Run-command and the Network Watcher agent need a running VM. After the 23:00
# auto-shutdown or the End-of-week cost control the VM is deallocated, so start it.
if [[ "$(az vm show -d -g "${RG}" -n "${VM}" --query powerState -o tsv)" != "VM running" ]]; then
  echo "==> Starting ${VM} (it was deallocated)"; az vm start -g "${RG}" -n "${VM}" -o none
fi
# The script below is built on your workstation, sent with --scripts @file, and run
# on the VM as root. It is safe to re-run. With FILE_METHOD="run-command" the three
# starter-kit files travel inside it, compressed (about 14 KB in total).
VM_SETUP="${WORK_DIR}/vm-setup.sh"
{
  echo "#!/usr/bin/env bash"
  # POSIX-safe guard: if the agent runs this file with /bin/sh (dash on Ubuntu), re-run it
  # with bash. The grep makes sure $0 really is this setup file before re-running it.
  echo 'if [ -z "${BASH_VERSION:-}" ]; then'
  echo '  grep -q mock-bureau-setup "$0" 2>/dev/null && exec /bin/bash "$0" "$@"'
  echo '  echo "ERROR: this setup script needs bash" >&2; exit 1'
  echo 'fi'
  echo "set -euo pipefail"
  echo "NODE_MAJOR='${NODE_MAJOR}'"
  echo "SRC=/var/lib/mock-bureau-src"
  echo 'mkdir -p "${SRC}"'
  if [[ "${FILE_METHOD}" == "run-command" ]]; then
    for f in "${BUREAU_FILES[@]}"; do
      echo "base64 -d <<'B64' | gunzip > \"\${SRC}/${f}\""
      b64gz "${BUREAU_SRC}/${f}"
      echo ""
      echo "B64"
    done
  fi
  cat <<'VMSCRIPT'
# ----- everything below runs on the VM, as root -----
export DEBIAN_FRONTEND=noninteractive NEEDRESTART_MODE=a
LOG=/var/log/mock-bureau-setup.log
exec 3>&1 >>"${LOG}" 2>&1          # details go to the log; say() prints the short status
say() { echo "$*" >&3; }
trap 'say "FAILED near line ${LINENO}. Last lines of ${LOG}:"; tail -n 15 "${LOG}" >&3' ERR
# Wait for first-boot work (cloud-init, unattended upgrades) to release apt.
# Match only the real apt workers: the always-running unattended-upgrade-shutdown
# helper must not count, or the loop would wait the full five minutes every time.
cloud-init status --wait || true
for i in $(seq 1 60); do
  pgrep -x apt-get >/dev/null || pgrep -x apt >/dev/null || pgrep -x dpkg >/dev/null \
    || pgrep -f '/usr/bin/unattended-upgrade( |$)' >/dev/null || break
  sleep 5
done
# 1. Node.js from NodeSource, only if the right major version is not there yet.
if ! node --version 2>/dev/null | grep -q "^v${NODE_MAJOR}\."; then
  curl -fsSL "https://deb.nodesource.com/setup_${NODE_MAJOR}.x" | bash -
  apt-get -o DPkg::Lock::Timeout=300 install -y nodejs
fi
# 2. An unprivileged service account. The service never runs as root.
id bureau >/dev/null 2>&1 || useradd --system --create-home --shell /usr/sbin/nologin bureau
install -d -o bureau -g bureau -m 755 /opt/mock-bureau
# 3. The three starter-kit files, then the locked dependencies (Express).
for f in server.js package.json package-lock.json; do
  if [ ! -s "${SRC}/${f}" ]; then say "MISSING ${SRC}/${f}"; exit 1; fi
  install -o bureau -g bureau -m 644 "${SRC}/${f}" /opt/mock-bureau/
done
cd /opt/mock-bureau
sudo -u bureau -H npm ci --omit=dev --no-audit --no-fund
# 4. The Week 3 systemd unit, unchanged.
cat > /etc/systemd/system/mock-bureau.service <<'UNIT'
[Unit]
Description=CSP451 mock credit bureau service (synthetic data only)
After=network-online.target
Wants=network-online.target
[Service]
Type=simple
User=bureau
Group=bureau
WorkingDirectory=/opt/mock-bureau
Environment=NODE_ENV=production
Environment=PORT=8080
Environment=HOST=0.0.0.0
ExecStart=/usr/bin/node /opt/mock-bureau/server.js
Restart=on-failure
RestartSec=5
StandardOutput=journal
StandardError=journal
SyslogIdentifier=mock-bureau
# Hardening. The service needs nothing beyond its own directory and a socket.
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/opt/mock-bureau
RestrictAddressFamilies=AF_INET AF_INET6
[Install]
WantedBy=multi-user.target
UNIT
systemctl daemon-reload
systemctl enable mock-bureau.service
systemctl restart mock-bureau.service
# 5. Host firewall, the second layer: 8080 from the app subnet only, no SSH rule.
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow from 10.20.2.0/24 to any port 8080 proto tcp comment 'Mock bureau service, app subnet only'
ufw --force enable
# 6. Wait for the service, then print a short status.
#    run-command returns only the last 4,096 bytes of output.
for i in $(seq 1 15); do
  curl -fsS http://127.0.0.1:8080/health >/dev/null 2>&1 && break
  sleep 2
done
say "node: $(node --version)"
say "service: $(systemctl is-active mock-bureau.service), $(systemctl is-enabled mock-bureau.service)"
say "process: $(ps -o user=,pid=,cmd= -C node)"
say "health: $(curl -s http://127.0.0.1:8080/health)"
ufw status numbered >&3
say "SETUP OK"
VMSCRIPT
} > "${VM_SETUP}"
echo "==> Running the VM setup through run-command (two to five minutes on the first run)"
SETUP_OUT=$(az vm run-command invoke -g "${RG}" -n "${VM}" --command-id RunShellScript \
  --scripts @"$(winpath "${VM_SETUP}")" --query "value[0].message" -o tsv)
echo "${SETUP_OUT}"
if ! printf '%s\n' "${SETUP_OUT}" | grep -q "SETUP OK"; then
  echo "ERROR: the VM setup did not finish. Read the output above and the Troubleshooting table." >&2
  exit 1
fi
# ---------------------------------------------------------------------------
# 11. Network Watcher agent (connection troubleshoot needs it), then a build report
# ---------------------------------------------------------------------------
echo "==> Installing the NetworkWatcherAgentLinux extension (about 30 seconds)"
az vm extension set -g "${RG}" --vm-name "${VM}" \
  --name NetworkWatcherAgentLinux --publisher Microsoft.Azure.NetworkWatcher -o none
echo "==> Subnets of ${VNET}"
az network vnet subnet list -g "${RG}" --vnet-name "${VNET}" \
  --query "[].{name:name, prefix:addressPrefix, outbound:defaultOutboundAccess, delegation:delegations[0].serviceName, nsg:networkSecurityGroup.id}" \
  -o table
for nsg in "${NSG_BUREAU}" "${NSG_APP}"; do
  echo "==> Rules in ${nsg}"
  az network nsg rule list -g "${RG}" --nsg-name "${nsg}" \
    --query "[].{name:name, priority:priority, dir:direction, access:access, proto:protocol, src:sourceAddressPrefix, dst:destinationAddressPrefix, port:destinationPortRange}" \
    -o table
done
echo "==> ${VM}"
az vm show -d -g "${RG}" -n "${VM}" \
  --query "{size:hardwareProfile.vmSize, disk:storageProfile.osDisk.managedDisk.storageAccountType, privateIp:privateIps, publicIp:publicIps, power:powerState}" \
  -o table
az resource show -g "${RG}" -n "shutdown-computevm-${VM}" \
  --resource-type Microsoft.DevTestLab/schedules \
  --query "{status:properties.status, time:properties.dailyRecurrence.time, timeZone:properties.timeZoneId}" -o table
echo "==> Resources in ${RG}"
az resource list -g "${RG}" --location "" --query "[].{Name:name, Type:type}" -o table
echo "==> Done. Collect the CP4 evidence with the blocks on the walkthrough page."
