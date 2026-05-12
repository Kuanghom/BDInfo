#!/usr/bin/env bash
#===============================================================================
# NFS 客户端一键安装并挂载（发起挂载的机器，例如跑 BDInfo Web 的宿主机）
# 适配：Debian/Ubuntu 系、RHEL/CentOS/Rocky/Alma/Fedora、Arch Linux、openSUSE
# 用法见：bash nfs-client-setup.sh --help
# 需要 root。
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
用法: sudo $SCRIPT_NAME --server <NFS服务器IP或主机名> --remote <服务端导出路径> --mount <本机挂载点> [选项]

必选:
  --server HOST       NFS 服务端地址
  --remote PATH       服务端 /etc/exports 中的目录，例如 /data/movies
  --mount PATH        本机挂载目录（不存在则 mkdir -p）

可选:
  --rw                读写挂载（默认只读 ro；需服务端同样导出为 rw）
  --nfs-vers N        NFS 版本，3 或 4（默认: 3，兼容性最好）
  --persist           将挂载项追加到 /etc/fstab（使用 _netdev，开机自动挂载）
  --dry-run           只打印，不安装、不挂载、不写 fstab

示例:
  sudo $SCRIPT_NAME --server 192.168.1.10 --remote /data/movies --mount /mnt/nfs/movies
  sudo $SCRIPT_NAME --server 10.0.0.5 --remote /export/bd --mount /mnt/nfs/bd --rw --persist
EOF
}

load_os_release() {
  if [[ -f /etc/os-release ]]; then
    # shellcheck source=/dev/null
    . /etc/os-release
    OS_ID="${ID:-}"
    OS_ID_LIKE="${ID_LIKE:-}"
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
    die "未支持的发行版 ID=$OS_ID；请手动安装 nfs 客户端后再执行挂载命令"
  fi
}

install_nfs_client_packages() {
  info "安装 NFS 客户端软件包 (发行版: $OS_ID)..."
  if is_debian_like; then
    pkg_install nfs-common
  elif is_rhel_like; then
    pkg_install nfs-utils
  elif is_arch_like; then
    pkg_install nfs-utils
  elif is_suse_like; then
    pkg_install nfs-client
  else
    die "未支持的发行版: $OS_ID"
  fi
}

# 仅当「该目录本身」已是挂载点时才视为占用。
# 注意：findmnt -T PATH 会打印「包含 PATH 的文件系统」的挂载点（未单独挂载时往往是 /），
# 不能用来判断 PATH 是否为 NFS 挂载点，否则会误报并阻止首次挂载。
mnt_busy() {
  local p="$1"
  if command -v mountpoint >/dev/null 2>&1; then
    mountpoint -q "$p" 2>/dev/null
    return $?
  fi
  if command -v findmnt >/dev/null 2>&1; then
    findmnt -n "$p" 2>/dev/null | grep -q .
    return $?
  fi
  awk -v d="$p" '$2==d {found=1} END{exit !found}' /proc/mounts 2>/dev/null
}

#-------------------------------------------------------------------------------
SERVER=""
REMOTE_PATH=""
MOUNT_POINT=""
MOUNT_RW="0"
NFS_VERS="3"
PERSIST="0"
DRY_RUN="0"

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    --server) SERVER="${2:-}"; shift 2 ;;
    --remote) REMOTE_PATH="${2:-}"; shift 2 ;;
    --mount) MOUNT_POINT="${2:-}"; shift 2 ;;
    --rw) MOUNT_RW="1"; shift ;;
    --nfs-vers) NFS_VERS="${2:-}"; shift 2 ;;
    --persist) PERSIST="1"; shift ;;
    --dry-run) DRY_RUN="1"; shift ;;
    *) die "未知参数: $1 （使用 --help）" ;;
  esac
done

[[ -n "$SERVER" && -n "$REMOTE_PATH" && -n "$MOUNT_POINT" ]] || { usage; exit 1; }

case "$NFS_VERS" in
  3|4) ;;
  *) die "--nfs-vers 仅支持 3 或 4" ;;
esac

need_root
load_os_release

MOUNT_POINT="$(readlink -f -m "$MOUNT_POINT")"
REMOTE_PATH="${REMOTE_PATH//\\/}"

# 构建 mount 选项
MOUNT_OPTS="vers=${NFS_VERS},soft,timeo=600,retrans=5,_netdev,nolock"
if [[ "$MOUNT_RW" == "1" ]]; then
  MOUNT_OPTS="rw,${MOUNT_OPTS}"
else
  MOUNT_OPTS="ro,${MOUNT_OPTS}"
fi

if [[ "$DRY_RUN" != "1" ]]; then
  install_nfs_client_packages
  mkdir -p "$MOUNT_POINT"
fi

# 若已挂载则拒绝（避免叠挂）；dry-run 时仅警告
if mnt_busy "$MOUNT_POINT"; then
  if [[ "$DRY_RUN" == "1" ]]; then
    warn "[dry-run] 挂载点 $MOUNT_POINT 上已有挂载，正式执行将退出；请先 umount"
  else
    warn "挂载点 $MOUNT_POINT 已是独立挂载点（避免叠挂）"
    if command -v findmnt >/dev/null 2>&1; then
      warn "详情: $(findmnt -n "$MOUNT_POINT" 2>/dev/null || true)"
    fi
    warn "若需更换请先: umount $MOUNT_POINT"
    exit 1
  fi
fi

REMOTE_NORM="${REMOTE_PATH}"
[[ "${REMOTE_NORM:0:1}" == / ]] || REMOTE_NORM="/${REMOTE_NORM}"

SRC="${SERVER}:${REMOTE_NORM}"

if [[ "$DRY_RUN" == "1" ]]; then
  info "[dry-run] mount -t nfs -o ${MOUNT_OPTS} ${SRC} ${MOUNT_POINT}"
else
  info "正在挂载: ${SRC} -> ${MOUNT_POINT}"
  mount -t nfs -o "$MOUNT_OPTS" "$SRC" "$MOUNT_POINT"
  findmnt "$MOUNT_POINT"
fi

FSTAB_LINE="${SRC} ${MOUNT_POINT} nfs ${MOUNT_OPTS} 0 0"
FSTAB_MARK="# bdinfo-nfs-client ${SRC} -> ${MOUNT_POINT}"

append_fstab() {
  if [[ "$PERSIST" != "1" ]]; then
    return 0
  fi
  if [[ "$DRY_RUN" == "1" ]]; then
    info "[dry-run] 追加 /etc/fstab:"
    echo "$FSTAB_MARK"
    echo "$FSTAB_LINE"
    return 0
  fi
  if grep -qF "$MOUNT_POINT" /etc/fstab 2>/dev/null; then
    warn "/etc/fstab 中已存在包含该挂载点的行，跳过写入"
    return 0
  fi
  printf '\n%s\n%s\n' "$FSTAB_MARK" "$FSTAB_LINE" >> /etc/fstab
  info "已写入 /etc/fstab；可用: mount -a 验证"
}

append_fstab

info "完成。Docker 映射示例:"
echo "  -v ${MOUNT_POINT}:/media/$(basename "$MOUNT_POINT"):ro"
