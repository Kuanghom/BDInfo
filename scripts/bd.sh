#!/bin/bash

# bd - 蓝光/普通视频截图和信息提取工具（无花屏最终版）
# 用法: bd <路径> [--count <数量>] [--grid ROWSxCOLS] [--lang LANGUAGE] [--info]
set +e

# ===================== 日志配置（修复date语法） =====================
LOG_DIR="$HOME/logs"
mkdir -p "$LOG_DIR"
# 日志文件名：精确到分钟（无空格，避免语法错误）
LOG_FILE="$LOG_DIR/bd-$(date +%Y%m%d-%H%M).log"
> "$LOG_FILE"  # 清空日志文件
# 核心修复：date格式带空格时必须用引号包裹
log_debug() {
    echo "【调试】$(date +"%Y-%m-%d %H:%M:%S") - $1" >> "$LOG_FILE"
}
# 错误日志函数（同时写日志+控制台）
log_error() {
    echo "【错误】$(date +"%Y-%m-%d %H:%M:%S") - $1" >> "$LOG_FILE"
    echo "错误: $1"
}


# 默认配置
COUNT=3
TARGET_DIR=""
MOUNT_POINT="/tmp/bd_mount"
GRID_LAYOUT=""
LANGUAGE="chinese"
OUTPUT_DIR=""
SHOW_INFO=false
MAX_PARALLEL=1  # 同步执行，稳定无错
SKIP_DEP_CHECK=false

# BDInfo 配置
BDINFO_URL_X64="https://github.com/dotnetcorecorner/BDInfo/releases/download/linux-2.0.6/bdinfo_linux_v2.0.6.zip"
BDINFO_URL_ARM64="https://github.com/Kuanghom/BDInfo/releases/download/arm64-2.0.6/bdinfo_linux_arm64_v2.0.6.zip"
INSTALL_DIR="/usr/local/bin"
TEMPDIR=$(mktemp -d)

# 确保临时文件可写
touch .image_url.txt
chmod 666 .image_url.txt
chmod 777 $TEMPDIR

# 解析参数
while [[ $# -gt 0 ]]; do
    case $1 in
        --count)
            COUNT="$2"
            shift 2
            ;;
        --grid)
            GRID_LAYOUT="$2"
            shift 2
            ;;
        --lang)
            LANGUAGE="$2"
            shift 2
            ;;
        --info)
            SHOW_INFO=true
            shift
            ;;
        *)
            if [[ -z "$TARGET_DIR" ]]; then
                TARGET_DIR="${1//\'/}"
                USER_SCREENSHOT_DIR="$HOME/screenshot"
                mkdir -p "$USER_SCREENSHOT_DIR"
                chmod 777 "$USER_SCREENSHOT_DIR"
                if [[ -f "$TARGET_DIR" ]]; then
                    SUBDIR_NAME=$(basename "$TARGET_DIR" | sed 's/[^a-zA-Z0-9._-]/_/g')
                else
                    SUBDIR_NAME=$(basename "$TARGET_DIR" | sed 's/[^a-zA-Z0-9._-]/_/g')
                fi
                OUTPUT_DIR="${USER_SCREENSHOT_DIR}/${SUBDIR_NAME}"
                mkdir -p "$OUTPUT_DIR"
                chmod 777 "$OUTPUT_DIR"
                log_debug "【调试】输出目录: $OUTPUT_DIR (权限: $(stat -c %a "$OUTPUT_DIR"))" >&2
            else
                echo "错误: 多余的参数 $1" >&2
                exit 1
            fi
            shift
            ;;
    esac
done

# 检查输出目录可写性
if [[ ! -w "$OUTPUT_DIR" ]]; then
    echo "错误: 输出目录不可写 - $OUTPUT_DIR" >&2
    sudo chmod 777 "$OUTPUT_DIR"
    if [[ ! -w "$OUTPUT_DIR" ]]; then
        echo "修复失败，请手动创建: mkdir -p $OUTPUT_DIR && chmod 777 $OUTPUT_DIR" >&2
        exit 1
    fi
fi

# 创建挂载点
mkdir -p "$MOUNT_POINT"
chmod 777 "$MOUNT_POINT"

# 安装依赖
install_dependencies() {
    if [[ "$SKIP_DEP_CHECK" == true ]]; then
        echo "跳过依赖检查..." >&2
        return 0
    fi
    local missing=()
    for cmd in ffmpeg curl jq pngquant mediainfo montage; do
        if ! command -v $cmd &>/dev/null; then
            missing+=("$cmd")
        fi
    done

    # 检查 ICU 库（区分不同包管理器）
    local icu_missing=false
    if command -v apt &>/dev/null; then
        if ! dpkg -l libicu-dev &>/dev/null; then
            missing+=("libicu-dev")
            icu_missing=true
        fi
    elif command -v yum &>/dev/null; then
        if ! rpm -q libicu &>/dev/null; then
            missing+=("libicu" "libicu-devel")
            icu_missing=true
        fi
    fi

    # ImageMagick 包名映射
    local imagemagick_pkg=""
    if command -v apt &>/dev/null; then
        imagemagick_pkg="imagemagick"
    elif command -v yum &>/dev/null; then
        imagemagick_pkg="ImageMagick"
    fi

    # 检查是否需要安装 ImageMagick
    if ! command -v montage &>/dev/null && [ -n "$imagemagick_pkg" ]; then
        missing+=("$imagemagick_pkg")
    fi


    if [ ${#missing[@]} -gt 0 ]; then
        echo "正在安装依赖: ${missing[*]}" >&2
        if command -v apt &>/dev/null; then
            sudo apt update && sudo apt install -y "${missing[@]}"
        elif command -v yum &>/dev/null; then
            sudo yum install -y "${missing[@]}"
        else
            echo "请手动安装依赖: ${missing[*]}" >&2
            exit 1
        fi
    fi
}

# 安装BDInfo
install_bdinfo() {
    if ! command -v BDInfo &>/dev/null; then
        # 检测系统架构
        local arch=$(uname -m)
        local bdinfo_url=""
        
        if [[ "$arch" == "aarch64" || "$arch" == "arm64" ]]; then
            echo "检测到ARM64架构，正在安装BDInfo..." >&2
            bdinfo_url="$BDINFO_URL_ARM64"
        else
            echo "检测到x86_64架构，正在安装BDInfo..." >&2
            bdinfo_url="$BDINFO_URL_X64"
        fi
        
        # 定义镜像列表
        local mirrors=(
            "$bdinfo_url"
            "https://ghfast.top/$bdinfo_url"
        )
        
        for mirror in "${mirrors[@]}"; do
            if wget -q "$mirror" -O "$TEMPDIR/bdinfo.zip"; then
                unzip -q -o "$TEMPDIR/bdinfo.zip" -d "$TEMPDIR"
                chmod +x "$TEMPDIR"/BDInfo*
                sudo cp "$TEMPDIR"/BDInfo* "$INSTALL_DIR/"
                rm -rf "$TEMPDIR"
                echo "BDInfo 安装成功!" >&2
                return 0
            fi
        done
        echo "错误: 无法下载BDInfo" >&2
        exit 1
    fi
}

# 检测输入类型
get_input_type() {
    local input="$1"
    if [ -f "$input" ]; then
        local ext=$(echo "$input" | awk -F. '{if (NF>1) print tolower($NF)}')
        case "$ext" in
            mkv|mp4|avi|mov|flv|wmv|m4v|ts|m2ts) echo "video"; return 0;;
            iso) echo "iso"; return 0;;
        esac
        echo "bdfile"
    elif [ -d "$input" ]; then
        if [ -d "$input/BDMV" ]; then
            echo "bdmv"
        elif [ -d "$input/VIDEO_TS" ]; then
            echo "dvd"
        else
            local iso_file=$(find "$input" -maxdepth 1 -type f \( -iname "*.iso" \) | head -1)
            if [ -n "$iso_file" ]; then
                echo "iso"
            else
                local video_file=$(find "$input" -maxdepth 1 -type f \( -iname "*.mkv" -o -iname "*.mp4" -o -iname "*.avi" -o -iname "*.mov" -o -iname "*.ts" -o -iname "*.m2ts" \) | head -1)
                if [ -n "$video_file" ]; then
                    echo "video_file:$video_file"
                else
                    echo "错误: 无有效视频/BD文件" >&2
                    exit 1
                fi
            fi
        fi
    else
        echo "错误: 无效路径" >&2
        exit 1
    fi
}

# 解析BDInfo
parse_bdinfo() {
    awk '
    BEGIN {RS = "DISC INFO:"; max_size=0; best_section=""}
    NR>1 {
        section="DISC INFO:"$0; sub(/FILES:.*/,"",section)
        if(match(section,/Size:[[:space:]]+([0-9,]+)/)){
            size_str=substr(section,RSTART+5,RLENGTH-5); gsub(/,/,"",size_str); size=size_str+0
            if(size>max_size){max_size=size; best_section=section}
        }
    }
    END {
        if(best_section!=""){sub(/[[:space:]]+$/,"",best_section); print "↓#↓#↓#↓#↓#↓#↓#↓#↓#↓#↓ BDInfo 信息 ↓#↓#↓#↓#↓#↓#↓#↓#↓#↓#↓"; print best_section; print "↑#↑#↑#↑#↑#↑#↑#↑#↑#↑#↑ 分割线 ↑#↑#↑#↑#↑#↑#↑#↑#↑#↑#↑"}
        else{print "错误: 无有效PLAYLIST" > "/dev/stderr"; exit 1}
    }'
}

# 提取BD信息
extract_bd_info() {
    local target="$1"
    install_bdinfo
    local bdinfo_file="$TEMPDIR/bdinfo_$$.txt"
    echo "正在提取BD信息..." >&2
    if BDInfo -p "$target" -o "$bdinfo_file"; then
        cp "$bdinfo_file" "${OUTPUT_DIR}/bdinfo.txt"
        parse_bdinfo < "$bdinfo_file"
        rm -f "$bdinfo_file"
    else
        echo "错误: BDInfo执行失败" >&2
        exit 1
    fi
}

# 提取MediaInfo
extract_mediainfo() {
    local target="$1"
    local mediainfo_file="${OUTPUT_DIR}/mediainfo.txt"
    echo "正在提取MediaInfo信息..." >&2
    if mediainfo "$target" > "$mediainfo_file"; then
        echo "↓#↓#↓#↓#↓#↓#↓#↓#↓#↓#↓ MediaInfo 信息 ↓#↓#↓#↓#↓#↓#↓#↓#↓#↓#↓"
        mediainfo --Output=Human "$target"
        echo "↑#↑#↑#↑#↑#↑#↑#↑#↑#↑#↑ 分割线 ↑#↑#↑#↑#↑#↑#↑#↑#↑#↑#↑"
    else
        echo "错误: MediaInfo执行失败" >&2
        exit 1
    fi
}

# 清理函数
cleanup() {
    if mountpoint -q "$MOUNT_POINT"; then
        sudo umount "$MOUNT_POINT" 2>/dev/null || true
    fi
    rm -rf "$MOUNT_POINT" "$TEMPDIR"
    wait 2>/dev/null || true
}
trap cleanup EXIT

# 压缩PNG
compress_png() {
    local file="$1"
    local max_size_bytes=$((10 * 1024 * 1024))
    local current_size=$(stat -c%s "$file" 2>/dev/null || echo 0)
    if ((current_size <= max_size_bytes)); then
        log_debug "【调试】文件无需压缩: $file ($current_size 字节)" 
        return 0
    fi
    if command -v pngquant &>/dev/null; then
        local temp_file="${file%.*}_compressed.png"
        log_debug "【调试】压缩图片: $file" >&2
        pngquant --force --skip-if-larger --output "$temp_file" --quality 60-75 "$file" 2>/dev/null
        if [[ -f "$temp_file" && -s "$temp_file" ]]; then
            mv "$temp_file" "$file"
            log_debug "【调试】压缩完成: $file" >&2
            return 0
        fi
    fi
    log_error "警告: 压缩失败，保留原文件" >&2
    return 1
}

# 上传图床
upload_to_pixhost() {
    local file="$1"
    local max_size_mb=10
    local max_retry=3
    local retry_count=0
    local size=$(stat -c%s "$file" 2>/dev/null || echo 0)
    if ((size > max_size_mb * 1024 * 1024)); then
        if ! compress_png "$file"; then
            echo "压缩失败，跳过上传" >&2
            return 1
        fi
    fi
    while ((retry_count < max_retry)); do
        local size=$(stat -c%s "$file" 2>/dev/null || echo 0)
        if ((size > max_size_mb * 1024 * 1024)); then
            echo "文件过大($((size/1024/1024))MB)，跳过上传" >&2
            return 1
        fi
        log_debug "【调试】上传图片: $file" >&2
        local response=$(curl -s -F "name=$(basename "$file")" -F "ajax=yes" -F "content_type=0" -F "file=@$file" "https://pixhost.to/new-upload/")
        if [ -z "$response" ]; then
            echo "上传失败(空响应)" >&2
        else
            local error=$(echo "$response" | jq -r '.error.description' 2>/dev/null)
            if [ "$error" != "null" ] && [ -n "$error" ]; then
                echo "上传失败($error)" >&2
            else
                local url=$(echo "$response" | jq -r '.show_url' | sed 's|\\||g;s|pixhost\.to/show|img2.pixhost.to/images|')
                echo "[img]$url[/img]"
				echo "$url" >> .image_url.txt
                log_debug "【调试】上传成功: $url" >&2
                return 0
            fi
        fi
        ((retry_count++))
        sleep 1
    done
    echo "上传失败: 超过最大重试次数" >&2
    return 1
}

# 获取视频时长（纯数字返回，无污染）
get_duration() {
    local input="$1"
    log_debug "【调试】获取时长: $input" >&2
    local duration=$(ffprobe -v quiet -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$input" 2>/dev/null | awk '{print int($1)}')
    log_debug "【调试】视频时长: $duration 秒" >&2
    echo "$duration"
}

# 获取字幕流序号（从0开始计数，仅字幕流）
# 返回: <字幕序号>,<字幕类型> 或空字符串
# 字幕类型: text(文本字幕) 或 graphic(图形字幕如PGS/VOBsub)
get_subtitle_index() {
    local input="$1"
    local language="$2"
    log_debug "【调试】查找字幕流: $language" >&2
    # 获取字幕流信息：索引、编解码、语言
    local subtitle_info=$(ffprobe -v error -select_streams s -show_entries stream=index,codec_name:stream_tags=language -of csv=p=0 "$input" 2>/dev/null)
    log_debug "【调试】字幕流原始信息: $subtitle_info" >&2
    if [[ -z "$subtitle_info" ]]; then
        log_debug "【调试】未找到字幕流" >&2
        echo ""
        return
    fi
    # 语言映射表（常见语言代码）
    declare -A lang_map=(
        ["chi"]="chinese"
        ["zho"]="chinese"
        ["zh"]="chinese"
        ["cht"]="chinese"
        ["chs"]="chinese"
        ["eng"]="english"
        ["en"]="english"
        ["jpn"]="japanese"
        ["ja"]="japanese"
        ["kor"]="korean"
        ["ko"]="korean"
    )
    # 文本字幕编解码列表（FFmpeg subtitles滤镜支持的格式）
    local text_codecs="srt ass ssa subrip webvtt mov_text"
    local sub_idx=0
    while IFS= read -r line; do
        local index=$(echo "$line" | cut -d',' -f1)
        local codec=$(echo "$line" | cut -d',' -f2 | tr '[:upper:]' '[:lower:]')
        local lang=$(echo "$line" | cut -d',' -f3 | tr '[:upper:]' '[:lower:]')
        log_debug "【调试】检查字幕流: 流索引=$index, 编解码=$codec, 字幕序号=$sub_idx, 语言代码=$lang" >&2
        # 判断字幕类型
        local sub_type="graphic"
        if [[ " $text_codecs " == *" $codec "* ]]; then
            sub_type="text"
        fi
        log_debug "【调试】字幕类型: $sub_type (编解码: $codec)" >&2
        # 转换为标准语言名称
        local normalized_lang="${lang_map[$lang]:-$lang}"
        local normalized_query="${lang_map[${language,,}]:-${language,,}}"
        log_debug "【调试】标准化后: 流语言=$normalized_lang, 查询语言=$normalized_query" >&2
        if [[ "$normalized_lang" == *"$normalized_query"* ]] || [[ "$lang" == *"${language,,}"* ]]; then
            log_debug "【调试】找到匹配字幕流: 流索引=$index, 字幕序号=$sub_idx, 类型=$sub_type (语言: $lang -> $normalized_lang)" >&2
            echo "$sub_idx,$sub_type"
            return
        fi
        ((sub_idx++))
    done <<< "$subtitle_info"
    log_error "【调试】未找到指定语言字幕流 (查找: $language)" >&2
    echo ""
}

# 创建拼图
create_grid_with_ffmpeg() {
    local input_files=("$@")
    local grid_file="${OUTPUT_DIR}/$(date +%s)_grid.png"
    local valid_files=()
    for file in "${input_files[@]}"; do
        if [[ -f "$file" && -s "$file" ]]; then
            valid_files+=("$file")
        else
            log_debug "【调试】无效截图文件: $file" >&2
        fi
    done
    if [[ ${#valid_files[@]} -eq 0 ]]; then
        echo "错误: 无有效截图用于拼图" >&2
        return 1
    fi
    local rows=2
    local cols=2
    if [[ -n "$GRID_LAYOUT" ]]; then
        rows=$(echo "$GRID_LAYOUT" | cut -d'x' -f1)
        cols=$(echo "$GRID_LAYOUT" | cut -d'x' -f2)
    fi
    log_debug "【调试】创建拼图: ${cols}x${rows}" >&2
    if [[ ${#valid_files[@]} -eq 1 ]]; then
        cp "${valid_files[0]}" "$grid_file"
    else
        # 使用vstack+hstack组合滤镜拼接（比xstack更兼容）
        local filter_complex=""
        
        # 为每个输入添加scale滤镜确保尺寸一致
        for ((i=0; i<${#valid_files[@]}; i++)); do
            filter_complex+="[$i:v]scale=512:288:force_original_aspect_ratio=decrease,pad=512:288:(ow-iw)/2:(oh-ih)/2:white,setsar=1[v$i];"
        done
        
        # 构建网格布局：按行分组，然后垂直堆叠
        local row_filters=""
        for ((row=0; row<rows; row++)); do
            local row_inputs=""
            for ((col=0; col<cols; col++)); do
                local idx=$((row * cols + col))
                if [[ $idx -lt ${#valid_files[@]} ]]; then
                    row_inputs+="[v$idx]"
                fi
            done
            if [[ -n "$row_inputs" ]]; then
                # 水平拼接每行
                filter_complex+="${row_inputs}hstack=inputs=$(echo "$row_inputs" | grep -o '\[' | wc -l)[row$row];"
            fi
        done
        
        # 垂直拼接所有行
        local all_rows=""
        for ((row=0; row<rows; row++)); do
            if [[ $((row * cols)) -lt ${#valid_files[@]} ]]; then
                all_rows+="[row$row]"
            fi
        done
        filter_complex+="${all_rows}vstack=inputs=$(echo "$all_rows" | grep -o '\[' | wc -l)[out]"
        
        local input_args=()
        for file in "${valid_files[@]}"; do input_args+=("-i" "$file"); done
        
        # 调试日志：输出完整的ffmpeg命令和参数
        log_debug "【调试】ffmpeg拼图参数:"
        log_debug "  - 输入文件数量: ${#valid_files[@]}"
        log_debug "  - 输入文件列表: ${valid_files[*]}"
        log_debug "  - 网格布局: ${cols}x${rows}"
        log_debug "  - filter_complex: $filter_complex"
        log_debug "  - 输出文件: $grid_file"
        
        # 执行ffmpeg并捕获错误输出
        local ffmpeg_error_file="$TEMPDIR/ffmpeg_error_$$.log"
        ffmpeg "${input_args[@]}" -filter_complex "$filter_complex" -map "[out]" -y "$grid_file" 2>"$ffmpeg_error_file"
        local ffmpeg_exit_code=$?
        
        if [[ $ffmpeg_exit_code -ne 0 ]]; then
            log_error "ffmpeg拼图失败 (退出码: $ffmpeg_exit_code)"
            if [[ -f "$ffmpeg_error_file" && -s "$ffmpeg_error_file" ]]; then
                log_error "ffmpeg错误输出:"
                cat "$ffmpeg_error_file" | head -20 >> "$LOG_FILE"
                echo "详细错误信息已记录到: $LOG_FILE" >&2
            fi
            echo "ffmpeg拼图失败，尝试montage备用方案..." >&2
            if command -v montage &>/dev/null; then
                log_debug "【调试】尝试montage备用方案"
                log_debug "  - montage命令: montage ${valid_files[*]} -geometry 512x -tile ${cols}x${rows} -background white $grid_file"
                local montage_error_file="$TEMPDIR/montage_error_$$.log"
                montage "${valid_files[@]}" -geometry 512x -tile "${cols}x${rows}" -background white "$grid_file" 2>"$montage_error_file"
                local montage_exit_code=$?
                if [[ $montage_exit_code -ne 0 ]]; then
                    log_error "montage拼图失败 (退出码: $montage_exit_code)"
                    if [[ -f "$montage_error_file" && -s "$montage_error_file" ]]; then
                        log_error "montage错误输出:"
                        cat "$montage_error_file" | head -20 >> "$LOG_FILE"
                    fi
                    echo "错误: montage拼图也失败" >&2
                    return 1
                fi
                log_debug "【调试】montage拼图成功"
            else
                echo "错误: montage命令不可用，无法创建拼图" >&2
                echo "提示: 请安装ImageMagick (apt install imagemagick 或 yum install ImageMagick)" >&2
                return 1
            fi
        fi
    fi
    if [[ -f "$grid_file" && -s "$grid_file" ]]; then
        log_debug "【调试】拼图生成成功: $grid_file" >&2
        if ! upload_to_pixhost "$grid_file"; then
            echo "拼图上传失败，本地保留: $grid_file" >&2
        fi
    else
        echo "错误: 拼图文件未生成" >&2
        return 1
    fi
}

# 核心处理：视频截图（无花屏+无语法错误）
process_video_file() {
    local video_file="$1"
    local TIMESTAMP=$(date +%s)
    local screenshot_files=()

    # 获取并校验时长
    local duration=$(get_duration "$video_file")
    if ! [[ "$duration" =~ ^[0-9]+$ ]]; then
        echo "错误: 时长无效 - '$duration'" >&2
        return 1
    fi
    local subtitle_info=$(get_subtitle_index "$video_file" "$LANGUAGE")
    local subtitle_index=""
    local subtitle_type=""
    if [[ -n "$subtitle_info" ]]; then
        subtitle_index=$(echo "$subtitle_info" | cut -d',' -f1)
        subtitle_type=$(echo "$subtitle_info" | cut -d',' -f2)
        log_debug "【调试】字幕信息: 序号=$subtitle_index, 类型=$subtitle_type" >&2
    fi
    local margin=120
    local available_duration=$((duration - 2 * margin))
    if ((duration == 0 || available_duration <= 0)); then
        echo "错误: 视频过短或时长无效 (${duration}秒)" >&2
        return 1
    fi

    # 计算截图数量和时间点
    local total_frames=$COUNT
    local rows=2
    local cols=2
    if [[ -n "$GRID_LAYOUT" ]]; then
        rows=$(echo "$GRID_LAYOUT" | cut -d'x' -f1)
        cols=$(echo "$GRID_LAYOUT" | cut -d'x' -f2)
        total_frames=$((rows * cols))
    fi
    local interval=$((available_duration / total_frames))
    local time_points=()
    for ((i=0; i<total_frames; i++)); do
        time_points+=($((margin + i * interval)))
    done

    echo "↓#↓#↓#↓#↓#↓#↓#↓#↓#↓#↓ 截图 ↓#↓#↓#↓#↓#↓#↓#↓#↓#↓#↓"
    local subtitle_display="无"
    local use_subtitle=false
    if [[ -n "$subtitle_index" ]]; then
        if [[ "$subtitle_type" == "text" ]]; then
            subtitle_display="序号$subtitle_index (文本字幕)"
            use_subtitle=true
        else
            subtitle_display="序号$subtitle_index (图形字幕,不支持烧录)"
            log_debug "【调试】图形字幕不支持FFmpeg烧录，将跳过字幕" >&2
        fi
    fi
    echo "视频时长: $duration 秒, 字幕流: $subtitle_display, 截图数量: $total_frames"

    # ========== 核心无花屏修复：混合Seek截图 ==========
    for ((i=0; i<total_frames; i++)); do
        local target_ts=${time_points[$i]}
        local seek_quick=$((target_ts - 1))  # 快速Seek到目标前1秒
        local seek_precise=1                 # 精准Seek1秒到目标位置
        local outfile="${OUTPUT_DIR}/${TIMESTAMP}_$(printf "%02d" $((i+1))).png"

        # 构建FFmpeg命令：混合Seek（快速+精准）→ 无花屏+速度快
        local ffmpeg_cmd=(
            ffmpeg
            -ss "$seek_quick"        # 第一步：快速Seek（基于关键帧，无解码，快）
            -i "$video_file"         # 输入文件
            -ss "$seek_precise"      # 第二步：精准Seek（仅解码1秒，无花屏）
            -loglevel error          # 只输错误，减少冗余
            -an                      # 禁用音频，节省资源
            -vframes 1               # 仅取1帧
            -c:v png                 # PNG编码器
            -compression_level 3     # 速度优先的压缩
            -y                       # 覆盖输出
        )

        # 字幕/缩放逻辑
        if [[ "$use_subtitle" == true ]]; then
            # 转义文件路径中的特殊字符（反斜杠、冒号、单引号）
            local escaped_file="${video_file//\\/\\\\}"
            escaped_file="${escaped_file//:/\\:}"
            escaped_file="${escaped_file//\'/\\\'}"
            if [[ -n "$GRID_LAYOUT" ]]; then
                ffmpeg_cmd+=(-vf "subtitles='$escaped_file':si=$subtitle_index,scale=512:-1")
            else
                ffmpeg_cmd+=(-vf "subtitles='$escaped_file':si=$subtitle_index")
            fi
        else
            if [[ -n "$GRID_LAYOUT" ]]; then
                ffmpeg_cmd+=(-vf "scale=512:-1")
            fi
        fi
        ffmpeg_cmd+=("$outfile")

        # 执行截图并校验
        log_debug "【调试】执行截图命令: ${ffmpeg_cmd[*]}" >&2
        local ffmpeg_output
        ffmpeg_output=$("${ffmpeg_cmd[@]}" 2>&1)
        local ffmpeg_exit=$?
        if [[ -n "$ffmpeg_output" ]]; then
            log_debug "【调试】ffmpeg 输出: $ffmpeg_output" >&2
        fi
        if [[ -f "$outfile" && -s "$outfile" ]]; then
            local file_size=$(stat -c "%s" "$outfile" | awk '{print $1/1024 " kb"}')
            screenshot_files+=("$outfile")
            compress_png "$outfile"
			local compress_file_size=$(stat -c "%s" "$outfile" | awk '{print $1/1024 " kb"}')
			echo "截图 $((i+1)) 完成: $target_ts 秒 -> 文件: $outfile (大小: $file_size , 压缩后: $compress_file_size)"
			
        else
            echo "错误: 截图 $((i+1)) 失败！文件不存在/为空: $outfile" >&2
            touch "$outfile"
        fi
    done

    # 拼图/上传
    if [[ ${#screenshot_files[@]} -eq 0 ]]; then
        echo "错误: 未生成任何有效截图" >&2
        return 1
    fi
    if [[ -n "$GRID_LAYOUT" ]]; then
        create_grid_with_ffmpeg "${screenshot_files[@]}"
    else
        for file in "${screenshot_files[@]}"; do
            if [[ -f "$file" && -s "$file" ]]; then
                upload_to_pixhost "$file"
            else
                echo "跳过上传无效文件: $file" >&2
            fi
        done
    fi
    log_debug "【调试】生成的截图文件:" >&2
    # ls -lh "${OUTPUT_DIR}"/*.png 2>/dev/null || echo "  无PNG文件生成" >&2
}

# 处理BDMV
process_bdmv() {
    local bdmv_dir="$1"
    local stream_dir="$bdmv_dir/BDMV/STREAM"
    if [[ ! -d "$stream_dir" ]]; then
        echo "错误: 无BDMV/STREAM目录: $stream_dir" >&2
        return 1
    fi
    echo "查找最大.m2ts文件..." >&2
    local largest_file=$(find "$stream_dir" -iname "*.m2ts" -type f -exec du -b {} \; | sort -nr | head -1 | cut -f2)
    if [[ -z "$largest_file" ]]; then
        echo "错误: 无.m2ts文件 in $stream_dir" >&2
        return 1
    fi
    echo "使用文件: $(basename "$largest_file") (路径: $largest_file)"
    if [[ "$SHOW_INFO" == true ]]; then
        extract_bd_info "$bdmv_dir"
        echo ""
    fi
    process_video_file "$largest_file"
}

# 处理ISO
process_iso() {
    local iso_file="$1"
    log_debug "【调试】挂载ISO: $iso_file -> $MOUNT_POINT" >&2
    if ! sudo mount -o loop "$iso_file" "$MOUNT_POINT" 2>/dev/null; then
        echo "错误: 无法挂载ISO" >&2
        return 1
    fi
    if [[ -d "$MOUNT_POINT/BDMV" ]]; then
        process_bdmv "$MOUNT_POINT"
    elif [[ -d "$MOUNT_POINT/VIDEO_TS" ]]; then
        process_dvd "$MOUNT_POINT"
    else
        echo "错误: 无法识别ISO格式" >&2
        return 1
    fi
    sudo umount "$MOUNT_POINT"
}

# 处理DVD
process_dvd() {
    local dvd_dir="$1"
    local video_ts_dir="$dvd_dir/VIDEO_TS"
    if [[ ! -d "$video_ts_dir" ]]; then
        echo "错误: 无VIDEO_TS目录" >&2
        return 1
    fi
    local largest_file=$(find "$video_ts_dir" -name "*.VOB" -type f -exec du -b {} \; | sort -nr | head -1 | cut -f2)
    if [[ -z "$largest_file" ]]; then
        echo "错误: 无.VOB文件" >&2
        return 1
    fi
    echo "使用文件: $(basename "$largest_file")"
    process_video_file "$largest_file"
}

# 处理普通视频
process_regular_video() {
    local video_file="$1"
    echo "检测到普通视频文件: $(basename "$video_file")"
    if [[ "$SHOW_INFO" == true ]]; then
        extract_mediainfo "$video_file"
        echo ""
    fi
    process_video_file "$video_file"
}

# 主函数
main() {
    install_dependencies
    if [[ -z "$TARGET_DIR" ]]; then
        echo "用法: $0 <路径> [--count <数量>] [--grid ROWSxCOLS] [--lang LANGUAGE] [--info]" >&2
        exit 1
    fi
    log_debug "【调试】处理路径: $TARGET_DIR" >&2
    log_debug "【调试】路径类型: $(if [[ -f "$TARGET_DIR" ]]; then echo "文件"; elif [[ -d "$TARGET_DIR" ]]; then echo "目录"; else echo "不存在"; fi)" >&2
    local input_type=$(get_input_type "$TARGET_DIR")
    case "$input_type" in
        bdmv) process_bdmv "$TARGET_DIR";;
        iso)
            if [[ -f "$TARGET_DIR" ]]; then
                process_iso "$TARGET_DIR"
            else
                local iso_file=$(find "$TARGET_DIR" -maxdepth 1 -type f \( -iname "*.iso" \) | head -1)
                [[ -n "$iso_file" ]] && process_iso "$iso_file" || (echo "错误: 无ISO文件" >&2 && exit 1)
            fi;;
        dvd) process_dvd "$TARGET_DIR";;
        video) process_regular_video "$TARGET_DIR";;
        video_file:*) process_regular_video "${input_type#video_file:}";;
        bdfile) process_video_file "$TARGET_DIR";;
        *) echo "错误: 不支持的类型: $input_type" >&2 && exit 1;;
    esac

    # 最终结果展示
    echo -e "\n↓#↓#↓#↓#↓#↓#↓#↓#↓#↓#↓ 完成 ↓#↓#↓#↓#↓#↓#↓#↓#↓#↓#↓"
    if [[ -f ".image_url.txt" && -s ".image_url.txt" ]]; then
        echo -e "\n----------------原始地址----------------\n"
        cat .image_url.txt
        rm .image_url.txt
    fi
}

# 启动
main "$@"
