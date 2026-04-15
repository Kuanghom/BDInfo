#!/bin/bash
set -euo pipefail  # 开启严格模式，出错时立即退出

# 定义关键路径
BD_SH_PATH="/root/bd.sh"
LINK_TARGET="/usr/local/bin/bd"
DOWNLOAD_URL="https://raw.githubusercontent.com/Kuanghom/BDInfo/main/scripts/bd.sh"


# 检查是否为root用户（创建/usr/local/bin链接需要root）
if [ "$(id -u)" -ne 0 ]; then
    echo "错误：请以root用户执行该脚本（或使用sudo）"
    exit 1
fi

# 检查下载工具（优先curl，其次wget）
if command -v curl &>/dev/null; then
    DOWNLOAD_CMD="curl -fSL $DOWNLOAD_URL -o $BD_SH_PATH"
elif command -v wget &>/dev/null; then
    DOWNLOAD_CMD="wget -O $BD_SH_PATH $DOWNLOAD_URL"
else
    echo "错误：未找到curl或wget，请先安装其中一个下载工具"
    exit 1
fi

# 开始执行核心步骤
echo "===== 1. 下载bd.sh脚本 ====="
echo "执行下载命令：$DOWNLOAD_CMD"
$DOWNLOAD_CMD

# 检查下载是否成功
if [ ! -f "$BD_SH_PATH" ]; then
    echo "错误：bd.sh脚本下载失败，请检查网络或URL是否正确"
    exit 1
fi
echo "✅ 脚本下载成功，路径：$BD_SH_PATH"

echo -e "\n===== 2. 增加执行权限 ====="
chmod +x "$BD_SH_PATH"
# 验证权限是否添加成功
if [ ! -x "$BD_SH_PATH" ]; then
    echo "错误：执行权限添加失败"
    exit 1
fi
echo "✅ 已为$BD_SH_PATH添加执行权限（chmod +x）"

echo -e "\n===== 3. 创建软链接 ====="
# 如果软链接已存在，先删除（避免冲突）
if [ -L "$LINK_TARGET" ] || [ -f "$LINK_TARGET" ]; then
    echo "提示：$LINK_TARGET已存在，先删除旧链接/文件"
    rm -f "$LINK_TARGET"
fi
# 创建软链接
ln -s "$BD_SH_PATH" "$LINK_TARGET"
# 验证软链接是否创建成功
if [ ! -L "$LINK_TARGET" ]; then
    echo "错误：软链接创建失败"
    exit 1
fi
echo "✅ 已创建软链接：$LINK_TARGET -> $BD_SH_PATH"

echo -e "\n===== 4. 修改/tmp目录权限为755 ====="
chmod 755 /tmp
# 验证权限修改结果
if [ "$(stat -c %a /tmp)" != "755" ]; then
    echo "警告：/tmp权限修改未生效，当前权限：$(stat -c %a /tmp)"
else
    echo "✅ /tmp目录权限已设置为755"
fi

echo -e "\n===== 所有步骤执行完成！====="
echo "验证：执行bd命令是否可调用脚本（输出脚本路径即成功）"
ls -l "$LINK_TARGET"
echo "✅ 脚本执行完毕，可直接在终端输入bd命令调用该脚本"