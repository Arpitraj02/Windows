#!/usr/bin/env bash

# dockur/windows TUI manager
# script by Ash

IMAGE="dockurr/windows"
DEFAULT_PORT_WEB=8006
DEFAULT_PORT_RDP=3389

# Colors
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
MAGENTA="\e[35m"
CYAN="\e[36m"
BOLD="\e[1m"
RESET="\e[0m"

CONFIG_DIR="${HOME}/.dockur-windows"
mkdir -p "$CONFIG_DIR"

banner() {
  clear
  echo -e "${CYAN}"
  echo "                                                      "
  echo "                                                      "
  echo "██     ██ ▄▄ ▄▄  ▄▄ ▄█████  ▄▄▄▄ ▄▄▄▄  ▄▄ ▄▄▄▄ ▄▄▄▄▄▄ "
  echo "██ ▄█▄ ██ ██ ███▄██ ▀▀▀▄▄▄ ██▀▀▀ ██▄█▄ ██ ██▄█▀  ██   "
  echo " ▀██▀██▀  ██ ██ ▀██ █████▀ ▀████ ██ ██ ██ ██     ██   "
  echo "                                                      "
  echo -e "${RESET}"
  echo -e "${MAGENTA}${BOLD}script by Ash${RESET}"
  echo
}

pause() {
  echo
  read -rp "Press Enter to continue..." _
}

config_file_for_vm() {
  local name="$1"
  echo "${CONFIG_DIR}/${name}.env"
}

list_configs() {
  ls "$CONFIG_DIR"/*.env 2>/dev/null | sed 's#.*/##;s#\.env$##'
}

select_vm() {
  local VMS vm i
  mapfile -t VMS < <(list_configs)
  if [ "${#VMS[@]}" -eq 0 ]; then
    echo -e "${RED}No VMs configured yet.${RESET}"
    return 1
  fi

  echo -e "${YELLOW}Available VMs:${RESET}"
  i=1
  for vm in "${VMS[@]}"; do
    echo "  $i) $vm"
    i=$((i+1))
  done

  echo
  read -rp "Select VM number: " choice
  if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt "${#VMS[@]}" ]; then
    echo -e "${RED}Invalid choice.${RESET}"
    return 1
  fi
  SELECTED_VM="${VMS[$((choice-1))]}"
  return 0
}

load_vm_config() {
  local name="$1"
  local CFG
  CFG="$(config_file_for_vm "$name")"
  # shellcheck source=/dev/null
  source "$CFG"
}

pick_windows_version() {
  echo -e "${CYAN}${BOLD}Select Windows version${RESET}"
  echo
  local options=(
    "11  - Windows 11 Pro"
    "11l - Windows 11 LTSC"
    "11e - Windows 11 Enterprise"
    "10  - Windows 10 Pro"
    "10l - Windows 10 LTSC"
    "10e - Windows 10 Enterprise"
    "8e  - Windows 8.1 Enterprise"
    "7u  - Windows 7 Ultimate"
    "vu  - Windows Vista Ultimate"
    "xp  - Windows XP Professional"
    "2k  - Windows 2000 Professional"
    "2025 - Windows Server 2025"
    "2022 - Windows Server 2022"
    "2019 - Windows Server 2019"
    "2016 - Windows Server 2016"
    "2012 - Windows Server 2012"
    "2008 - Windows Server 2008"
    "2003 - Windows Server 2003"
    "CUSTOM - Enter ISO URL or manual value"
  )

  local i=1
  for o in "${options[@]}"; do
    echo "  $i) $o"
    i=$((i+1))
  done
  echo
  read -rp "Choice [1-19]: " vch

  case "$vch" in
    1) VERSION="11" ;;
    2) VERSION="11l" ;;
    3) VERSION="11e" ;;
    4) VERSION="10" ;;
    5) VERSION="10l" ;;
    6) VERSION="10e" ;;
    7) VERSION="8e" ;;
    8) VERSION="7u" ;;
    9) VERSION="vu" ;;
    10) VERSION="xp" ;;
    11) VERSION="2k" ;;
    12) VERSION="2025" ;;
    13) VERSION="2022" ;;
    14) VERSION="2019" ;;
    15) VERSION="2016" ;;
    16) VERSION="2012" ;;
    17) VERSION="2008" ;;
    18) VERSION="2003" ;;
    19)
      read -rp "Enter VERSION value or ISO URL: " custom_ver
      VERSION="$custom_ver"
      ;;
    *)
      echo -e "${RED}Invalid choice, using default: 11${RESET}"
      VERSION="11"
      ;;
  esac
}

create_or_edit_config() {
  banner
  echo -e "${YELLOW}${BOLD}Create / Edit VM configuration${RESET}"
  echo
  read -rp "VM name (no spaces): " VM_NAME
  [ -z "$VM_NAME" ] && echo -e "${RED}Name required.${RESET}" && pause && return

  local CFG
  CFG="$(config_file_for_vm "$VM_NAME")"

  [ -f "$CFG" ] && source "$CFG"

  echo
  echo -e "${CYAN}Windows version:${RESET}"
  pick_windows_version
  echo -e "${GREEN}Selected VERSION=${VERSION}${RESET}"
  echo

  read -rp "CPU cores [${CPU_CORES:-2}]: " cpu
  CPU_CORES="${cpu:-${CPU_CORES:-2}}"

  read -rp "RAM size (e.g. 4G, 8G) [${RAM_SIZE:-4G}]: " ram
  RAM_SIZE="${ram:-${RAM_SIZE:-4G}}"

  read -rp "Disk size (e.g. 64G, 128G) [${DISK_SIZE:-64G}]: " disk
  DISK_SIZE="${disk:-${DISK_SIZE:-64G}}"

  read -rp "Second disk size (e.g. 32G, empty to disable) [${DISK2_SIZE:-}]: " disk2
  DISK2_SIZE="${disk2:-${DISK2_SIZE:-}}"

  read -rp "RDP port on host [${RDP_PORT:-$DEFAULT_PORT_RDP}]: " rdp
  RDP_PORT="${rdp:-${RDP_PORT:-$DEFAULT_PORT_RDP}}"

  read -rp "Web viewer port on host [${WEB_PORT:-$DEFAULT_PORT_WEB}]: " web
  WEB_PORT="${web:-${WEB_PORT:-$DEFAULT_PORT_WEB}}"

  read -rp "Username [${USERNAME:-Docker}]: " user
  USERNAME="${user:-${USERNAME:-Docker}}"

  read -rp "Password [${PASSWORD:-admin}]: " pass
  PASSWORD="${pass:-${PASSWORD:-admin}}"

  read -rp "Windows LANGUAGE (e.g. English, French) [${LANGUAGE:-English}]: " lang
  LANGUAGE="${lang:-${LANGUAGE:-English}}"

  read -rp "REGION (e.g. en-US, fr-FR) [${REGION:-en-US}]: " reg
  REGION="${reg:-${REGION:-en-US}}"

  read -rp "KEYBOARD layout (e.g. en-US) [${KEYBOARD:-en-US}]: " keyb
  KEYBOARD="${keyb:-${KEYBOARD:-en-US}}"

  read -rp "Storage path on host (for main disk) [${STORAGE_PATH:-$PWD/windows-$VM_NAME}]: " stor
  STORAGE_PATH="${stor:-${STORAGE_PATH:-$PWD/windows-$VM_NAME}}"

  read -rp "Second disk storage path (if DISK2_SIZE set) [${STORAGE2_PATH:-$PWD/${VM_NAME}-disk2}]: " stor2
  STORAGE2_PATH="${stor2:-${STORAGE2_PATH:-$PWD/${VM_NAME}-disk2}}"

  read -rp "Shared folder on host (mounted to /shared, empty to skip) [${SHARED_PATH:-}]: " shared
  SHARED_PATH="${shared:-${SHARED_PATH:-}}"

  read -rp "OEM folder with install.bat (mounted to /oem, empty to skip) [${OEM_PATH:-}]: " oem
  OEM_PATH="${oem:-${OEM_PATH:-}}"

  mkdir -p "$STORAGE_PATH"
  [ -n "$DISK2_SIZE" ] && mkdir -p "$STORAGE2_PATH"

  cat > "$CFG" <<EOF
VM_NAME="$VM_NAME"
VERSION="$VERSION"
CPU_CORES="$CPU_CORES"
RAM_SIZE="$RAM_SIZE"
DISK_SIZE="$DISK_SIZE"
DISK2_SIZE="$DISK2_SIZE"
RDP_PORT="$RDP_PORT"
WEB_PORT="$WEB_PORT"
USERNAME="$USERNAME"
PASSWORD="$PASSWORD"
LANGUAGE="$LANGUAGE"
REGION="$REGION"
KEYBOARD="$KEYBOARD"
STORAGE_PATH="$STORAGE_PATH"
STORAGE2_PATH="$STORAGE2_PATH"
SHARED_PATH="$SHARED_PATH"
OEM_PATH="$OEM_PATH"
EOF

  echo
  echo -e "${GREEN}Configuration saved for VM '${VM_NAME}'.${RESET}"
  pause
}

configure_idx() {
  banner
  echo -e "${CYAN}${BOLD}Configure IDX Nix environment${RESET}"
  echo
  echo -e "${YELLOW}This will:${RESET}"
  echo -e "  1. Remove old .idx folder completely"
  echo -e "  2. Create new .idx/dev.nix with minimal working config"
  echo -e "  3. Include Docker, KVM, bash, git, curl"
  echo

  read -rp "Continue? [y/N]: " ans
  case "$ans" in
    y|Y) ;;
    *) echo -e "${RED}Aborted.${RESET}"; pause; return ;;
  esac

  echo
  echo -e "${YELLOW}[STEP 1/3] Removing old .idx folder...${RESET}"
  if [ -d .idx ]; then
    rm -rf .idx
    echo -e "${GREEN}Old .idx folder removed.${RESET}"
  else
    echo -e "${CYAN}.idx folder did not exist, creating fresh.${RESET}"
  fi

  echo -e "${YELLOW}[STEP 2/3] Creating .idx directory...${RESET}"
  mkdir -p .idx
  echo -e "${GREEN}.idx directory created.${RESET}"

  echo -e "${YELLOW}[STEP 3/3] Writing .idx/dev.nix...${RESET}"
  
  cat > .idx/dev.nix <<'EOF'
{ pkgs, ... }: {
  channel = "stable-24.05";

  packages = with pkgs; [
    bash
    coreutils
    git
    curl
    docker
    qemu_kvm
    nettools
  ];

  idx = {
    extensions = [
      "ms-vscode-remote.remote-containers"
    ];

    previews = {
      enable = true;
    };
  };
}
EOF

  if [ -f .idx/dev.nix ]; then
    local size
    size=$(wc -c < .idx/dev.nix)
    echo -e "${GREEN}.idx/dev.nix written successfully (${size} bytes).${RESET}"
    echo
    echo -e "${CYAN}Content preview:${RESET}"
    head -10 .idx/dev.nix | sed 's/^/  /'
    echo
  else
    echo -e "${RED}Failed to write .idx/dev.nix${RESET}"
    pause
    return 1
  fi

  echo -e "${MAGENTA}${BOLD}NEXT STEPS IN IDX UI:${RESET}"
  echo -e "  1. Open left sidebar"
  echo -e "  2. Click ${BOLD}Environment${RESET} tab (gear icon)"
  echo -e "  3. Verify .idx/dev.nix is shown"
  echo -e "  4. Click ${BOLD}\"Rebuild environment\"${RESET} button"
  echo -e "  5. Wait 30-90 seconds for rebuild to complete"
  echo
  echo -e "${GREEN}After rebuild, test in terminal:${RESET}"
  echo -e "  ${BOLD}docker --version${RESET}"
  echo -e "  ${BOLD}./winvm.sh${RESET}"
  pause
}

check_docker_env() {
  echo -e "${CYAN}[ENV] Checking Docker availability...${RESET}"
  if ! command -v docker >/dev/null 2>&1; then
    echo -e "${RED}[ENV] docker CLI not found in PATH.${RESET}"
    echo -e "${YELLOW}[ENV] Run option 8 to configure IDX, then rebuild.${RESET}"
    return 1
  fi

  if ! docker info >/dev/null 2>&1; then
    echo -e "${RED}[ENV] docker daemon not reachable.${RESET}"
    echo -e "${YELLOW}[ENV] Check permissions or wait for IDX to start Docker service.${RESET}"
    return 1
  fi

  echo -e "${GREEN}[ENV] Docker is ready.${RESET}"
  
  echo -e "${CYAN}[ENV] Checking /dev/kvm for acceleration...${RESET}"
  if [ -e /dev/kvm ]; then
    echo -e "${GREEN}[ENV] /dev/kvm present. KVM acceleration available.${RESET}"
  else
    echo -e "${YELLOW}[ENV] /dev/kvm missing. VM will run without hardware acceleration.${RESET}"
  fi
  return 0
}

realtime_start_log() {
  local name="$1"
  local web="$2"
  local rdp="$3"
  echo
  echo -e "${MAGENTA}${BOLD}========== VM START LOG (${name}) ==========${RESET}"
  echo -e "${CYAN}[VM] Container name: ${name}${RESET}"
  echo -e "${CYAN}[VM] Web viewer:     http://localhost:${web}${RESET}"
  echo -e "${CYAN}[VM] RDP:            localhost:${rdp}${RESET}"
  echo -e "${CYAN}[VM] Credentials:    Username/Password from config${RESET}"
  echo

  echo -e "${YELLOW}[LOG] Waiting for container to reach running state...${RESET}"

  for i in $(seq 1 30); do
    local state
    state=$(docker inspect -f '{{.State.Status}}' "$name" 2>/dev/null || echo "missing")
    echo -e "${BLUE}[LOG] Check ${i}/30: container status = ${state}${RESET}"
    if [ "$state" = "running" ]; then
      echo -e "${GREEN}[LOG] Container is running!${RESET}"
      break
    fi
    sleep 2
  done

  echo
  echo -e "${YELLOW}[LOG] Streaming Windows installation logs...${RESET}"
  echo -e "${YELLOW}[LOG] Press Ctrl+C to stop viewing (VM will keep running)${RESET}"
  echo -e "${MAGENTA}${BOLD}===========================================${RESET}"
  echo

  docker logs -f "$name" 2>&1 | while IFS= read -r line; do
    echo -e "${CYAN}[DOCKER]${RESET} $line"
  done
}

create_or_start_vm() {
  banner
  echo -e "${GREEN}${BOLD}Create / Start VM${RESET}"
  echo

  if ! select_vm; then
    echo
    echo -e "${YELLOW}Use option 1 to create a configuration first.${RESET}"
    pause
    return
  fi

  load_vm_config "$SELECTED_VM"
  check_docker_env || { pause; return; }

  echo
  echo -e "${CYAN}[BUILD] Constructing docker run command for '${VM_NAME}'...${RESET}"

  local run_cmd=(
    docker run -d
    --name "$VM_NAME"
    --restart always
    -e "VERSION=${VERSION}"
    -e "CPU_CORES=${CPU_CORES}"
    -e "RAM_SIZE=${RAM_SIZE}"
    -e "DISK_SIZE=${DISK_SIZE}"
    -e "USERNAME=${USERNAME}"
    -e "PASSWORD=${PASSWORD}"
    -e "LANGUAGE=${LANGUAGE}"
    -e "REGION=${REGION}"
    -e "KEYBOARD=${KEYBOARD}"
    -p "${WEB_PORT}:8006"
    -p "${RDP_PORT}:3389/tcp"
    -p "${RDP_PORT}:3389/udp"
    --device=/dev/kvm
    --device=/dev/net/tun
    --cap-add NET_ADMIN
    -v "${STORAGE_PATH}:/storage"
    --stop-timeout 120
  )

  if [ -n "$DISK2_SIZE" ]; then
    run_cmd+=(-e "DISK2_SIZE=${DISK2_SIZE}")
    run_cmd+=(-v "${STORAGE2_PATH}:/storage2")
    echo -e "${CYAN}[BUILD] Added second disk: ${DISK2_SIZE}${RESET}"
  fi

  if [ -n "$SHARED_PATH" ]; then
    run_cmd+=(-v "${SHARED_PATH}:/shared")
    echo -e "${CYAN}[BUILD] Added shared folder: ${SHARED_PATH}${RESET}"
  fi

  if [ -n "$OEM_PATH" ]; then
    run_cmd+=(-v "${OEM_PATH}:/oem")
    echo -e "${CYAN}[BUILD] Added OEM folder: ${OEM_PATH}${RESET}"
  fi

  run_cmd+=("$IMAGE")

  echo
  echo -e "${YELLOW}[BUILD] Full command:${RESET}"
  echo -e "${BLUE}${run_cmd[*]}${RESET}"
  echo

  echo -e "${YELLOW}[EXEC] Removing any existing container with same name...${RESET}"
  docker rm -f "$VM_NAME" >/dev/null 2>&1

  echo -e "${YELLOW}[EXEC] Starting container...${RESET}"
  if "${run_cmd[@]}" >/dev/null 2>&1; then
    echo -e "${GREEN}[EXEC] Container '${VM_NAME}' created successfully.${RESET}"
    realtime_start_log "$VM_NAME" "$WEB_PORT" "$RDP_PORT"
  else
    echo -e "${RED}[EXEC] Failed to start VM '${VM_NAME}'.${RESET}"
    echo -e "${YELLOW}Run: docker logs ${VM_NAME}${RESET}"
  fi
  pause
}

start_vm_only() {
  banner
  echo -e "${GREEN}${BOLD}Start existing VM${RESET}"
  echo

  if ! select_vm; then
    pause
    return
  fi

  load_vm_config "$SELECTED_VM"
  check_docker_env || { pause; return; }

  echo -e "${YELLOW}[EXEC] Starting container '${VM_NAME}'...${RESET}"
  if docker start "$VM_NAME" >/dev/null 2>&1; then
    echo -e "${GREEN}[EXEC] VM '${VM_NAME}' started.${RESET}"
    realtime_start_log "$VM_NAME" "$WEB_PORT" "$RDP_PORT"
  else
    echo -e "${RED}[EXEC] Failed to start container '${VM_NAME}'.${RESET}"
    echo -e "${YELLOW}Container may not exist. Use option 2 to create it.${RESET}"
    pause
  fi
}

stop_vm() {
  banner
  echo -e "${RED}${BOLD}Stop VM${RESET}"
  echo

  if ! select_vm; then
    pause
    return
  fi

  load_vm_config "$SELECTED_VM"
  check_docker_env || { pause; return; }

  echo -e "${YELLOW}[EXEC] Stopping container '${VM_NAME}'...${RESET}"
  if docker stop "$VM_NAME" >/dev/null 2>&1; then
    echo -e "${GREEN}[EXEC] VM '${VM_NAME}' stopped successfully.${RESET}"
  else
    echo -e "${RED}[EXEC] Failed to stop VM '${VM_NAME}'.${RESET}"
  fi
  pause
}

delete_vm() {
  banner
  echo -e "${RED}${BOLD}Delete VM container${RESET}"
  echo

  if ! select_vm; then
    pause
    return
  fi

  load_vm_config "$SELECTED_VM"
  check_docker_env || { pause; return; }

  echo -e "${YELLOW}This will delete the container only.${RESET}"
  echo -e "${YELLOW}Config and disk storage will be preserved.${RESET}"
  echo
  read -rp "Delete container '${VM_NAME}'? [y/N]: " ans
  case "$ans" in
    y|Y)
      if docker rm -f "$VM_NAME" >/dev/null 2>&1; then
        echo -e "${GREEN}[EXEC] Container '${VM_NAME}' deleted.${RESET}"
      else
        echo -e "${RED}[EXEC] Failed to delete container '${VM_NAME}'.${RESET}"
      fi
      ;;
    *)
      echo -e "${CYAN}Cancelled.${RESET}"
      ;;
  esac
  pause
}

show_vm_info() {
  banner
  echo -e "${CYAN}${BOLD}VM Information${RESET}"
  echo

  if ! select_vm; then
    pause
    return
  fi

  load_vm_config "$SELECTED_VM"

  echo -e "${BOLD}VM Name:${RESET}           $VM_NAME"
  echo -e "${BOLD}Windows VERSION:${RESET}   $VERSION"
  echo -e "${BOLD}CPU Cores:${RESET}         $CPU_CORES"
  echo -e "${BOLD}RAM Size:${RESET}          $RAM_SIZE"
  echo -e "${BOLD}Disk Size:${RESET}         $DISK_SIZE"
  echo -e "${BOLD}Second Disk:${RESET}       ${DISK2_SIZE:-<none>}"
  echo -e "${BOLD}Web Port:${RESET}          $WEB_PORT"
  echo -e "${BOLD}RDP Port:${RESET}          $RDP_PORT"
  echo -e "${BOLD}Username:${RESET}          $USERNAME"
  echo -e "${BOLD}Password:${RESET}          $PASSWORD"
  echo -e "${BOLD}Language:${RESET}          $LANGUAGE"
  echo -e "${BOLD}Region:${RESET}            $REGION"
  echo -e "${BOLD}Keyboard:${RESET}          $KEYBOARD"
  echo -e "${BOLD}Storage Path:${RESET}      $STORAGE_PATH"
  echo -e "${BOLD}Storage2 Path:${RESET}     ${STORAGE2_PATH:-<none>}"
  echo -e "${BOLD}Shared Path:${RESET}       ${SHARED_PATH:-<none>}"
  echo -e "${BOLD}OEM Path:${RESET}          ${OEM_PATH:-<none>}"
  echo
  echo -e "${YELLOW}Connection Info:${RESET}"
  echo -e "  RDP:  ${BOLD}localhost:${RDP_PORT}${RESET}"
  echo -e "  Web:  ${BOLD}http://localhost:${WEB_PORT}${RESET}"
  pause
}

list_all_vms() {
  banner
  echo -e "${CYAN}${BOLD}All Configured VMs${RESET}"
  echo
  local VMS
  mapfile -t VMS < <(list_configs)
  if [ "${#VMS[@]}" -eq 0 ]; then
    echo -e "${RED}No VM configurations found.${RESET}"
    echo -e "${YELLOW}Use option 1 to create a new VM configuration.${RESET}"
    pause
    return
  fi
  
  local i=1
  for vm in "${VMS[@]}"; do
    echo -e "${GREEN}${i}. ${vm}${RESET}"
    i=$((i+1))
  done
  pause
}

main_menu() {
  while true; do
    banner
    echo -e "${BLUE}${BOLD}Main Menu${RESET}"
    echo
    echo -e "  ${GREEN}1)${RESET} Create / Edit VM configuration"
    echo -e "  ${GREEN}2)${RESET} Create and Start VM"
    echo -e "  ${GREEN}3)${RESET} Start existing VM"
    echo -e "  ${GREEN}4)${RESET} Stop VM"
    echo -e "  ${GREEN}5)${RESET} Show VM info"
    echo -e "  ${GREEN}6)${RESET} Delete VM container"
    echo -e "  ${GREEN}7)${RESET} List all configured VMs"
    echo -e "  ${CYAN}8)${RESET} ${BOLD}Configure IDX (Nix environment)${RESET}"
    echo -e "  ${GREEN}0)${RESET} Exit"
    echo
    read -rp "Choose an option: " opt

    case "$opt" in
      1) create_or_edit_config ;;
      2) create_or_start_vm ;;
      3) start_vm_only ;;
      4) stop_vm ;;
      5) show_vm_info ;;
      6) delete_vm ;;
      7) list_all_vms ;;
      8) configure_idx ;;
      0) echo -e "${MAGENTA}Goodbye!${RESET}"; exit 0 ;;
      *) echo -e "${RED}Invalid option.${RESET}"; sleep 1 ;;
    esac
  done
}

main_menu
