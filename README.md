# BDInfo

手动编译 https://github.com/dotnetcorecorner/BDInfo 项目的arm64架构的版本

# BDInfo

可在多平台上扫描蓝光光盘（全高清、超高清、3D）。提供的二进制文件为便携版，无需安装任何运行框架。

## 命令参数

| 短参数 | 长参数 | 说明 | 必填 | 默认值 |
| --- | --- | --- | --- | --- |
| _`-p`_ | _`--path`_ | ISO 文件或蓝光文件夹路径	 | ✅ |  |
| _`-g`_ | _`--generatestreamdiagnostics`_ | 生成流诊断信息 |  | False |
| _`-e`_ | _`--extendedstreamdiagnostics`_ | 生成扩展流诊断信息 |  | False |
| _`-b`_ | _`--enablessif`_ | 启用 SSIF 支持 |  | False |
| _`-l`_ | _`--filterloopingplaylists`_ | 过滤循环播放列表 |  | False |
| _`-y`_ | _`--filtershortplaylist`_ | 过滤过短播放列表 |  | True |
| _`-v`_ | _`--filtershortplaylistvalue`_ | 短播放列表过滤阈值 |  | 20 |
| _`-k`_ | _`--keepstreamorder`_ | 保留流顺序 |  | False |
| _`-m`_ | _`--generatetextsummary`_ | 生成文本摘要 |  | True |
| _`-o`_ | _`--reportfilename`_ | 报告文件名（含扩展名），无扩展名则自动补 .txt |  |  |
| _`-q`_ | _`--includeversionandnotes`_ | 报告中包含版本与备注信息 |  | False |
| _`-j`_ | _`--groupbytime`_ | 按时长分组 |  | False |


Linux 系统下，使用 `chmod +x BDInfo` 为无扩展名的 `BDInfo` 文件添加可执行权限。

## How to use 

### Windows
`BDInfo.exe -p 光盘文件夹路径 -o 报告保存路径.扩展名`  
`BDInfo.exe -p ISO文件路径 -o 报告保存路径.扩展名`  

### Linux  
`./BDInfo -p 光盘文件夹路径 -o 报告保存路径.扩展名`  
`./BDInfo -p ISO文件路径 -o 报告保存路径.扩展名`

# BDExtractor

可在多平台上直接提取蓝光 ISO 文件内容，无需挂载（非 EEF 格式 ISO 除外）。提供的二进制文件为便携版，无需安装任何运行框架。

## 命令参数

| 短参数 | 长参数 | 说明 | 必填 |
| --- | --- | --- | --- |
| _`-p`_ | _`--path`_ | ISO 文件路径 | ✅ |
| _`-o`_ | _`--output`_ | 输出文件夹（不指定则解压到 ISO 同级目录） |  |

Linux 系统下，使用 `chmod +x BDExtractor` 为无扩展名的 `BDExtractor` 文件添加可执行权限。
## 使用方法

### Windows
`BDExtractor.exe -p PATH_TO_ISO_FILE -o FOLDER_OUTPUT`  
`BDExtractor.exe -p PATH_TO_ISO_FILE`  

### Linux:  
`./BDExtractor -p PATH_TO_ISO_FILE -o FOLDER_OUTPUT`
`./BDExtractor -p PATH_TO_ISO_FILE`

# BDInfoDataSubstractor (beta)

根据多种规则从超长文本中提取主播放列表。

## 使用方法

### Windows
`BDInfoDataSubstractor.exe bdinfo.txt bdinfo2.txt`

### Linux
`./BDInfoDataSubstractor bdinfo.txt bdinfo2.txt`

 ---

# bd.sh 脚本

蓝光/普通视频截图和信息提取工具，支持自动截图、字幕渲染、拼图、图床上传等功能。


## 功能特性

- 支持多种输入类型：BDMV 蓝光文件夹、ISO 镜像、DVD、普通视频文件（mkv/mp4/avi/m2ts 等）
- 自动提取视频截图并上传到 Pixhost 图床
- 支持字幕渲染（可指定语言）
- 支持截图拼图功能
- 可提取 BDInfo（蓝光）或 MediaInfo（普通视频）详细信息
- 自动安装所需依赖和 BDInfo 工具
- 
## 安装方式
```shell
bash <(curl -fsSL https://raw.githubusercontent.com/Kuanghom/BDInfo/main/scripts/installBDTool.sh)
```

## 命令参数

| 参数 | 说明 | 必填 | 默认值 |
| --- | --- |----| --- |
| `<路径>` | ISO 文件、蓝光文件夹或视频文件路径 | ✅  | |
| `--count <数量>` | 截图数量 |    | 3 |
| `--grid ROWSxCOLS` | 拼图布局（如 2x2、3x3），启用后将截图拼成一张图 |    | |
| `--lang <语言>` | 字幕语言（如 chinese、english） |    | chinese |
| `--info` | 显示详细信息（蓝光显示 BDInfo，普通视频显示 MediaInfo） |    | False |

## 依赖工具

脚本会自动检测并安装以下依赖：
- ffmpeg
- curl
- jq
- pngquant
- mediainfo
- libicu-dev / libicu
- BDInfo（根据系统架构自动选择 x64 或 arm64 版本）

## 使用方法
<img src="/.images/bd-01.png" width="750"> <!-- 高度自动按比例缩放 -->



### 基础截图
```bash
# 对普通视频截取3张截图
./bd.sh /path/to/video.mkv

# 对蓝光文件夹截图
./bd.sh /path/to/BDMV_FOLDER

# 对 ISO 镜像截图
./bd.sh /path/to/movie.iso
```

### 指定截图数量
```bash
# 截取5张截图
./bd.sh /path/to/video.mp4 --count 5
```

### 拼图模式
```bash
# 6张截图拼成2x3布局
./bd.sh /path/to/video.mkv --grid 2x3

# 9张截图拼成3x3布局
./bd.sh /path/to/bd_folder --count 9 --grid 3x3
```

### 显示详细信息
```bash
# 提取蓝光 BDInfo 信息并截图
./bd.sh /path/to/BDMV_FOLDER --info

# 提取视频 MediaInfo 信息并截图
./bd.sh /path/to/video.mp4 --info
```

### 指定字幕语言
```bash
# 渲染英文字幕截图
./bd.sh /path/to/video.mkv --lang english
```

### 综合示例
```bash
# 提取蓝光信息、渲染中文字幕、6张截图拼成2x3
./bd.sh /path/to/movie.iso --info --lang chinese --count 6 --grid 2x3
```

## 输出说明

- 截图文件保存至：`$HOME/screenshot/<文件名>/`
- 日志文件保存至：`$HOME/logs/bd-YYYYMMDD-HHMM.log`
- 上传成功后输出 BBCode 格式的图片链接



