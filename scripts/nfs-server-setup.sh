#!/usr/bin/env bash
#===============================================================================
# NFS 服务端一键配置（被挂载的服务器）
# 适配：Debian/Ubuntu 系、RHEL/CentOS/Rocky/Alma/Fedora、Arch Linux、openSUSE
# 用法见：bash nfs-server-setup.sh --help
# 需要 root；会安装 NFS 内核服务、写入 /etc/exports 片段并 reload。
#===============================================================================
set -euo pipefail

SCRIPT_NAME="$(basename "$0")"

die() { echo "错误: $*" >&2; exit 1; }
info() { echo "[*] $*"; }
warn() { echo "[!] $*" >&2; }

need_root() {
  if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
    die "请使用 root 执行: sudo $SCRIPT_NAME ..."
  fi
}

usage() {
  cat <<EOF
用法: sudo $SCRIPT_NAME --export <导出目录> --subnet <允许访问的网段> [选项]

必选:
  --export PATH       要共享给 NFS 的目录（须已存在，会先 mkdir -p）
  --subnet CIDR       允许挂载的客户端网段，例如 192.168.1.0/24 或 10.0.0.0/8

可选:
  --rw                导出为可读写（默认: 只读 ro）
  --no-root-squash    不对客户端 root 做 squash（安全风险高，仅内网调试慎用）
  --comment TEXT      写入 exports 时的注释标记，便于日后识别
  --dry-run           只打印将要执行的操作，不写文件、不启服务

说明:
  - 默认使用 sync、no_subtree_check、insecure（部分环境需要）
  - 防火墙需自行放行 NFS（脚本结束会打印 firewalld / ufw 示例）
  - 多目录请多次运行本脚本，每次一对 --export/--subnet；或手工编辑 /etc/exports

示例:
  sudo $SCRIPT_NAME --export /data/movies --subnet 192.168.1.0/24
  sudo $SCRIPT_NAME --export /data/bd --subnet 10.0.0.0/8 --rw
EOF
}

# 加载 os-release（POSIX 兼容）
load_os_release() {
  if [[ -f /etc/os-release ]]; then
    # shellcheck source=/dev/null
    . /etc/os-release
    OS_ID="${ID:-}"
    OS_ID_LIKE="${ID_LIKE:-}"
    OS_VERSION_ID="${VERSION_ID:-}"
  else
    die "未找到 /etc/os-release，无法识别发行版"
  fi
}

is_debian_like() {
  case ",${OS_ID},${OS_ID_LIKE}," in
    *,debian,*|*,ubuntu,*) return 0 ;;
  esac
  [[ "$OS_ID" == "linuxmint" || "$OS_ID" == "pop" ]] && return 0
  return 1
}

is_rhel_like() {
  case "$OS_ID" in
    fedora|rhel|centos|rocky|almalinux|ol|amzn|anolis|opencloudos|tencentos) return 0 ;;
  esac
  case ",${OS_ID_LIKE}," in
    *,rhel,*) return 0 ;;
  esac
  return 1
}

is_arch_like() {
  [[ "$OS_ID" == "arch" || "$OS_ID" == "manjaro" ]] && return 0
  return 1
}

is_suse_like() {
  [[ "$OS_ID" == "opensuse-leap" || "$OS_ID" == "opensuse-tumbleweed" || "$OS_ID" == "sles" ]] && return 0
  return 1
}

have_cmd() { command -v "$1" >/dev/null 2>&1; }

pkg_install() {
  local pkgs=("$@")
  if is_debian_like; then
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -qq
    apt-get install -y -qq "${pkgs[@]}"
  elif is_rhel_like; then
    if have_cmd dnf; then
      dnf install -y "${pkgs[@]}"
    elif have_cmd yum; then
      yum install -y "${pkgs[@]}"
    else
      die "未找到 dnf/yum"
    fi
  elif is_arch_like; then
    pacman -Sy --noconfirm "${pkgs[@]}"
  elif is_suse_like; then
    zypper --non-interactive install -y "${pkgs[@]}"
  else
    die "未支持的发行版 ID=$OS_ID；请手动安装 NFS 服务端后配置 /etc/exports"
  fi
}

install_nfs_server_packages() {
  info "安装 NFS 服务端软件包 (发行版: $OS_ID)..."
  if is_debian_like; then
    pkg_install nfs-kernel-server
  elif is_rhel_like; then
    pkg_install nfs-utils
  elif is_arch_like; then
    pkg_install nfs-utils
  elif is_suse_like; then
    pkg_install nfs-kernel-server
  else
    die "未支持的发行版: $OS_ID"
  fi
}

nfs_server_unit() {
  if is_debian_like; then
    echo "nfs-kernel-server"
  else
    # RHEL/Fedora/Arch/openSUSE 等常见单元名
    echo "nfs-server"
  fi
}

enable_start_nfs_server() {
  local unit
  unit="$(nfs_server_unit)"
  if [[ "$DRY_RUN" == "1" ]]; then
    info "[dry-run] systemctl enable --now $unit"
    return 0
  fi
  systemctl enable "$unit" 2>/dev/null || true
  systemctl restart "$unit"
  systemctl --no-pager --quiet is-active "$unit" || die "服务 $unit 未能处于 active 状态，请 journalctl -u $unit -e 查看日志"
  info "服务已启动: $unit"
}

reload_exports() {
  if [[ "$DRY_RUN" == "1" ]]; then
    info "[dry-run] exportfs -rav"
    return 0
  fi
  exportfs -rav
}

MARK_BEGIN="# >>> bdinfo-nfs-server-setup"
MARK_END="# <<< bdinfo-nfs-server-setup"

append_exports() {
  local export_path="$1"
  local subnet="$2"
  local opts="$3"
  local comment_tag="${4:-}"

  local block
  block="${MARK_BEGIN} ${comment_tag}
${export_path} ${subnet}(${opts})
${MARK_END}"

  if [[ "$DRY_RUN" == "1" ]]; then
    info "[dry-run] 将追加到 /etc/exports:"
    echo "$block"
    return 0
  fi

  if [[ -f /etc/exports ]] && grep -qF "${export_path} ${subnet}" /etc/exports 2>/dev/null; then
    warn "/etc/exports 中似乎已存在相同导出行，跳过追加。如需修改请手工编辑后执行: exportfs -rav"
    return 0
  fi

  if [[ -f /etc/exports ]] && grep -q "$MARK_BEGIN" /etc/exports 2>/dev/null; then
    warn "检测到本脚本历史标记块，仍将追加新块；建议定期整理 /etc/exports"
  fi

  printf '\n%s\n' "$block" >> /etc/exports
  info "已追加 /etc/exports"
}

print_firewall_hints() {
  local subnet="$1"
  echo ""
  info "防火墙放行提示（按需执行其一）："
  echo "  # firewalld (RHEL/Fedora 等)"
  echo "  firewall-cmd --permanent --add-service=nfs"
  echo "  firewall-cmd --permanent --add-service=mountd"
  echo "  firewall-cmd --permanent --add-service=rpc-bind"
  echo "  firewall-cmd --reload"
  echo ""
  echo "  # ufw (Ubuntu/Debian 若启用 ufw)"
  echo "  ufw allow from ${subnet} to any port nfs comment 'NFS'"
  echo "  ufw allow from ${subnet} to any port 111 comment 'rpcbind'"
  echo "  # 若仍不通，可临时: ufw status verbose 对照 nfs 相关端口"
}

#-------------------------------------------------------------------------------
EXPORT_PATH=""
SUBNET=""
EXPORT_RW="0"
NO_ROOT_SQUASH="0"
COMMENT_TAG=""
DRY_RUN="0"

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    --export) EXPORT_PATH="${2:-}"; shift 2 ;;
    --subnet) SUBNET="${2:-}"; shift 2 ;;
    --rw) EXPORT_RW="1"; shift ;;
    --no-root-squash) NO_ROOT_SQUASH="1"; shift ;;
    --comment) COMMENT_TAG="${2:-}"; shift 2 ;;
    --dry-run) DRY_RUN="1"; shift ;;
    *) die "未知参数: $1 （使用 --help）" ;;
  esac
done

[[ -n "$EXPORT_PATH" && -n "$SUBNET" ]] || { usage; exit 1; }

need_root
load_os_release

# 规范化路径
EXPORT_PATH="$(readlink -f -m "$EXPORT_PATH")"

OPTS="sync,no_subtree_check,insecure"
if [[ "$EXPORT_RW" == "1" ]]; then
  OPTS="rw,${OPTS}"
else
  OPTS="ro,${OPTS}"
fi
if [[ "$NO_ROOT_SQUASH" == "1" ]]; then
  OPTS="${OPTS},no_root_squash"
else
  OPTS="${OPTS},root_squash"
fi

if [[ "$DRY_RUN" != "1" ]]; then
  mkdir -p "$EXPORT_PATH"
fi

if [[ "$DRY_RUN" != "1" ]]; then
  install_nfs_server_packages
fi

append_exports "$EXPORT_PATH" "$SUBNET" "$OPTS" "$COMMENT_TAG"
enable_start_nfs_server
reload_exports

info "NFS 导出已生效: ${EXPORT_PATH} -> ${SUBNET} (${OPTS})"
info "客户端挂载示例（在 BDInfo 宿主机执行）:"
echo "  sudo mkdir -p /mnt/nfs/host && sudo mount -t nfs -o vers=3,soft,timeo=600 <本机IP>:${EXPORT_PATH} /mnt/nfs/host"
print_firewall_hints "$SUBNET"
