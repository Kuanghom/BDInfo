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




# BDInfo Web 使用说明

在浏览器中管理蓝光原盘与视频目录：浏览文件、预览常见格式、提取 **MediaInfo / BDInfo**、生成截图并自动上传到 **Pixhost** 图床、一键复制论坛用 BBCode，以及异步制作 BT 种子等。

---

## 使用 Docker 部署

以下说明假设你使用已发布的镜像 **`kuanghom/bdweb:latest`**（或等价镜像名）。容器内 Web 服务默认监听 **`18188`**，因此 `-p` 左侧写你希望对外暴露的宿主机端口，右侧写 **`18188`**。

### 准备宿主机目录（可选但推荐）

将日志和任务输出挂到宿主机，容器删除后数据仍保留：

```bash
sudo mkdir -p /data/bdweb/logs /data/bdweb/output
```

### 基本运行命令（默认关闭文件删除，媒体只读）

将 **`/path/to/your/media`** 换成你存放蓝光原盘、ISO、Remux 或普通视频的目录：

```bash
docker pull kuanghom/bdweb:latest

docker run -d \
  --name bdweb \
  --privileged \
  -p 18188:18188 \
  -v /path/to/your/media:/media:ro \
  -v /data/bdweb/logs:/data/bdinfo/logs \
  -v /data/bdweb/output:/data/bdinfo/output \
  --restart unless-stopped \
  kuanghom/bdweb:latest
```

浏览器访问：`http://<宿主机IP>:18188`。

若希望对外使用 **8181** 端口，将 `-p` 改为：

```bash
-p 8181:18188
```

则访问 `http://<宿主机IP>:8181`。

### 示例：开启文件浏览器删除

在需要**通过网页右键删除**浏览根目录内的文件或文件夹时，增加环境变量 **`BDINFO_BROWSER_DELETE_ENABLED=true`**。媒体目录必须对容器**可写**，请使用 **`:rw`**（或不写权限后缀，默认可写），**不要使用 `:ro`**，否则删除会在系统层面失败。

```bash
docker pull kuanghom/bdweb:latest

docker run -d \
  --name bdweb \
  --privileged \
  -p 18188:18188 \
  -e BDINFO_BROWSER_DELETE_ENABLED=true \
  -v /path/to/your/media:/media \
  -v /data/bdweb/logs:/data/bdinfo/logs \
  -v /data/bdweb/output:/data/bdinfo/output \
  --restart unless-stopped \
  kuanghom/bdweb:latest
```

开启删除后请务必确认浏览根目录范围正确，并限制可登录人员；生产环境仍建议配合宿主机文件权限与备份策略。

### 完整示例：删除 + 自定义端口 + 登录账号密码 + 数据持久化

下面示例同时指定：**对外端口 8181**、**开启删除**（媒体卷可写）、**首次初始化用的用户名与明文密码**、以及将 **凭据 / 日志 / 输出** 挂到宿主机目录，便于升级镜像后不丢失数据。

将 **`/path/to/your/media`**、**`./bdweb-data`** 等路径换成你本机实际路径（Windows 下可用 `E:/Movies` 这类写法）。

```bash
docker pull kuanghom/bdweb:latest

mkdir -p ./bdweb-data ./bdweb-logs ./bdweb-output

docker run -d \
  --name bdweb \
  --privileged \
  -p 8181:18188 \
  -e TZ=Asia/Shanghai \
  -e BDINFO_BROWSER_DELETE_ENABLED=true \
  -e BDINFO_AUTH_USERNAME=myadmin \
  -e BDINFO_AUTH_PASSWORD='ChangeMe_StrongPassword' \
  -e BDINFO_AUTH_PASSWORD_FILE=/data/bdinfo/data/password.json \
  -v /path/to/your/media:/media \
  -v "$(pwd)/bdweb-data:/data/bdinfo/data" \
  -v "$(pwd)/bdweb-logs:/data/bdinfo/logs" \
  -v "$(pwd)/bdweb-output:/data/bdinfo/output" \
  --restart unless-stopped \
  kuanghom/bdweb:latest
```

在 **Windows PowerShell** 下可将上述三行中的 `$(pwd)` 改为 `` `${PWD}` ``，或改为绝对路径（如 `E:/docker/bdweb-data:/data/bdinfo/data`）。

访问 **`http://<宿主机IP>:8181`**，使用 **`myadmin` / `ChangeMe_StrongPassword`** 登录（请立即改为强密码）。

**说明**：

- `BDINFO_AUTH_USERNAME` / `BDINFO_AUTH_PASSWORD` 主要在 **`password.json` 尚不存在**时用于生成初始凭据；若 `./bdweb-data` 里已有 `password.json`，则以文件内容为准（在网页里修改密码也会写回该文件）。
- 单引号包裹密码可避免 shell 对特殊字符误解析；密码中若含单引号需另行转义或改用 Compose。
- 容器内应用端口仍为 **18188**，未改 `SERVER_PORT`；仅通过 `-p 8181:18188` 映射到宿主机。

### 多服务节点挂载部署




##### NFS服务端 (假设ip为: 192.33.107.25)
```bash
bash <(curl -fsSL 'https://raw.githubusercontent.com/Kuanghom/BDInfo/main/scripts/nfs-server-setup.sh')   \
--export /home/admin/Downloads   \
--subnet 152.55.245.30/32
```

`解释: --export 要挂载的目录  --subnet 允许访问的ip`

##### NFS客户端 (装BD WEB的那个端) (假设ip为: 152.55.245.30)
```bash
bash <(wget -qO- https://raw.githubusercontent.com/Kuanghom/BDInfo/main/scripts/nfs-client-setup.sh) \
--server 192.33.107.25 \
--remote /home/admin/Downloads  \
--mount /mnt/nfs/1923310725
```


`解释: --server nfs服务端地址  --remote 远程挂载的目录, 这里为NFS服务端--export的一致 --mount 挂载到本地的目录`

##### Docker部署命令
```bash
docker pull kuanghom/bdweb:latest

mkdir -p ./bdweb-data ./bdweb-logs ./bdweb-output


docker run -d   --name bdweb   --privileged   -p 18188:18188  \
-e BDINFO_BROWSER_DELETE_ENABLED=true \
-e BDINFO_AUTH_USERNAME=账号 \
-e BDINFO_AUTH_PASSWORD='密码' \
-v /home/admin/Downloads:/media/localhost \
-v /mnt/nfs/1923310725:/media/1923310725 \
-v /data/bdweb/logs:/data/bdinfo/logs \
-v /data/bdweb/output:/data/bdinfo/output \
--restart unless-stopped   \
kuanghom/bdweb:latest
```
`解释: -v /home/admin/Downloads:/media/localhost 这个目录为本地的媒体目录  -v /mnt/nfs/1923310725:/media/1923310725 
这个目录为NFS服务端挂载的媒体目录`

### Docker Compose 部署

仓库根目录提供示例文件 **`docker-compose.example.yml`**，内容与下面等价。可复制为 `docker-compose.yml` 后修改路径与密码，再执行：

```bash
docker compose up -d
```

```yaml
services:
  bdweb:
    image: kuanghom/bdweb:latest
    container_name: bdweb
    privileged: true
    restart: unless-stopped
    ports:
      - "8181:18188"
    environment:
      TZ: Asia/Shanghai
      BDINFO_BROWSER_DELETE_ENABLED: "true"
      BDINFO_AUTH_USERNAME: "myadmin"
      BDINFO_AUTH_PASSWORD: "ChangeMe_StrongPassword"
      BDINFO_AUTH_PASSWORD_FILE: /data/bdinfo/data/password.json
    volumes:
      - /path/to/your/media:/media
      - ./bdweb-data:/data/bdinfo/data
      - ./bdweb-logs:/data/bdinfo/logs
      - ./bdweb-output:/data/bdinfo/output
```

停止与删除容器（保留宿主机挂载目录中的数据）：

```bash
docker compose down
```

### 只读挂载 `:ro` 与删除功能的关系

- **`BDINFO_BROWSER_DELETE_ENABLED`** 只决定**应用是否提供删除入口**以及后端是否接受删除请求。
- 若将媒体挂载为 **`-v ...:/media:ro`**，该挂载点在容器内对整个目录树是**只读**的，内核会拒绝创建、修改、**删除**等写操作。此时即使打开删除开关，删除也会失败（常见表现为权限不足或只读文件系统类错误），**不是再给 Docker 或应用某个「额外权限」就能删掉的**。
- **要在浏览根下真正删除文件**：请去掉 `:ro`，改为可写挂载（例如 `-v /path/to/media:/media` 或显式 `-v ...:/media:rw`），并保证宿主机上该目录对容器内进程有写权限（默认常以 root 运行，具体以你的镜像与安全配置为准）。

不需要删除时，继续使用 **`:ro`** 可从挂载层面防止误删，更安全。

### 为何需要 `--privileged`

当任务需要**在容器内挂载 ISO** 等操作时，通常需要 **`--privileged`**。若你仅浏览文件夹与普通视频文件、不涉及 ISO 挂载，可按安全策略尝试去掉该参数（若任务失败再恢复）。

### 多块磁盘或多个媒体库

把不同宿主机目录挂到容器内 **`/media` 下的不同子路径** 即可，例如：

```bash
-v /disk1/iso:/media/v1:ro \
-v /disk2/remux:/media/v2:ro \
```

在网页中会看到 `/media/v1`、`/media/v2` 等并列目录。若要对某一库开启删除，对应卷需可写（去掉 `:ro`）。

**Windows 宿主机**：`-v` 左侧使用 Docker Desktop 可识别的路径，例如 `E:/Movies:/media:ro`。

### 容器内常用路径

| 路径 | 含义 |
|------|------|
| `/media` | 默认媒体根目录（与配置 `BDINFO_ROOT_PATH` / `bdinfo.root-path` 对应） |
| `/data/bdinfo/logs` | 应用日志，建议挂载 |
| `/data/bdinfo/output` | 任务输出（媒体信息文本、截图、种子等），建议挂载 |
| `/data/bdinfo/data/password.json` | 默认登录凭据文件位置（可通过环境变量修改） |
| 与 `password.json` 同目录下的 `bdinfo-torrent-jobs.json` | 默认种子任务列表持久化文件 |

### 常用环境变量

通过 `docker run -e 变量=值` 传入。名称不区分大小写。

| 变量 | 作用 |
|------|------|
| `SERVER_PORT` | HTTP 端口（默认 `18188`，一般无需改，改端口更常用 `-p` 映射） |
| `BDINFO_AUTH_ENABLED` | 是否启用登录（默认 `true`） |
| `BDINFO_AUTH_USERNAME` / `BDINFO_AUTH_PASSWORD` | 首次生成凭据时的用户名与明文密码 |
| `BDINFO_AUTH_PASSWORD_FILE` | 凭据 JSON 文件路径（默认 `/data/bdinfo/data/password.json`） |
| `BDINFO_ROOT_PATH` | 文件浏览器与任务的根路径（默认 `/media`） |
| `BDINFO_BROWSER_DELETE_ENABLED` | 是否允许浏览器内删除（`true` / `false`；**官方镜像默认常为 `false`**） |
| `BDINFO_TORRENT_JOBS_FILE` | 种子任务列表 JSON 路径；不设置则使用与密码文件同目录的 `bdinfo-torrent-jobs.json` |
| `BDINFO_DIST_DIR` | BDInfo 离线包所在目录（镜像内已预置） |
| `BDINFO_INSTALL_DIR` | BDInfo 解压安装目录（镜像内默认常见为 `/usr/local/bin`） |
| `BD_MOUNT_POINT` | ISO 等临时挂载父目录（默认 `/data/bdinfo/mnt`） |
| `TZ` | 时区（镜像默认多为 `Asia/Shanghai`） |

种子相关进阶项（超时时间、保留任务条数、种子保存目录等）也可通过环境变量覆盖，命名方式为 **`BDINFO_TORRENT_` + 大写下划线**（与镜像内配置文件中的 `bdinfo.torrent.*` 项对应）。需要更多卷映射与多路径示例时，可参考仓库内 **`docs/DOCKER.md`**。

### 自定义配置文件（可选）

若需整体替换应用配置，可将你的 `application.yml` 挂载到容器内：

`/data/bdinfo/config/application.yml`

注意挂载后应自行保证其中的路径、端口等与容器环境一致。

### 持久化建议

- 媒体库：不需要删除时使用 `-v 宿主机目录:/media:ro` 只读挂载，降低误删风险；需要删除时改为可写挂载，见上文。
- 日志与输出：务必挂载 `/data/bdinfo/logs` 与 `/data/bdinfo/output`（或你自定义的等价路径）。
- 若希望**升级镜像后登录账号与种子任务列表不丢失**，将 **`/data/bdinfo/data`** 整个目录挂载到宿主机，或使用 `BDINFO_AUTH_PASSWORD_FILE` / `BDINFO_TORRENT_JOBS_FILE` 指向宿主机上的固定文件。

---

## 访问与登录

在浏览器中打开服务地址（端口以你部署时映射为准）：

| 场景 | 示例 |
|------|------|
| 公网 | `http://<服务器IP>:8181`（若将容器内 `18188` 映射到宿主机 `8181`） |
| 本机 | `http://localhost:18188` |
| 移动版布局 | 在地址后加 `?view=mobile`，例如 `http://localhost:18188/?view=mobile` |

开启登录后，使用管理员账号进入（首次可在环境中配置，默认如下）：

- **用户名**：`admin`
- **密码**：`adminbdinfo`

公网部署请务必**尽快修改密码**；修改后凭据保存在服务器上的密码文件中，之后以该文件为准。

### 登录页

![登录页](https://img2.pixhost.to/images/7836/725203511_.png)

---

## 界面一览

### PC 端主页

用于日常操作：左侧为文件列表与种子任务区，中间为「已选择目标」与信息/截图选项，下方为执行日志与截图展示。

![PC 端主页](https://img2.pixhost.to/images/7836/725202300_.png)

### 移动端主页

窄屏下布局更紧凑，同样支持浏览目录、选择目标、配置信息提取与截图、查看日志与截图；顶部可切换主题风格。

![移动端主页](https://img2.pixhost.to/images/7836/725202289_.png)

---

## 功能说明

### 1. 文件浏览

在管理员配置的**浏览根目录**（Docker 默认将宿主机的媒体目录映射为容器内的 `/media`）下，你可以：

- **查看目录与文件**：进入子目录、返回上一级、刷新列表、一键回到浏览根。
- **排序**：按名称、创建时间、修改时间、大小等排序，并可切换升序/降序。
- **搜索**：在当前目录内按名称过滤列表，便于在大量文件中定位。
- **进入方式**：文件夹可单击选中，也可通过「进入」或双击进入目录。
- **设为当前目标**：左键单击条目会将该文件或文件夹设为下方「已选择目标」，用于后续「开始执行」批量任务；右键菜单里也可「设为当前目标」。
- **复制路径**：右键可将服务器上的完整路径复制到剪贴板，便于粘贴到其它工具。

**删除功能**：在开启「文件浏览器删除」（环境变量 `BDINFO_BROWSER_DELETE_ENABLED=true`）时，右键会出现删除入口，删除前会弹出确认，且只能删除**浏览根目录范围内**的路径。**官方 Docker 镜像默认关闭删除**。若要在网页中真正删除媒体文件，媒体卷须**可写挂载**（不能使用 `:ro`），详见上文 **「只读挂载 `:ro` 与删除功能的关系」**。

### 2. 文件预览

对支持的视频、图片以及部分文档类文件，可在右键菜单中选择 **「查看 / 预览」**，在弹窗中直接预览内容，无需先下载到本地。

![文件预览](https://img2.pixhost.to/images/7836/725202310_.gif)

### 3. 媒体信息（MediaInfo / BDInfo）与截图

对选中的目录、视频文件或蓝光原盘结构，可：

- **勾选「生成媒体信息」**：由后台自动判断走 **BDInfo**（蓝光原盘）或 **MediaInfo**（一般视频等）流程，生成对应的文本报告。
- **勾选「截图」**：可设置截图张数（例如 3～20 张）、字幕烧录策略、是否使用拼图（多宫格合成一张）、以及 PNG 压缩方式与画质，以控制体积与清晰度。

任务执行过程中，日志区域会**实时滚动**输出进度；可随时 **停止** 当前任务。

截图在服务端生成后，会**自动上传到 Pixhost 图床**，日志中会出现图床链接。执行完成后你可以：

- **复制媒体信息**：一键复制解析后的摘要文本（便于发贴或存档）。
- **复制媒体信息 BBCode**：在弹窗中勾选 `[Mediainfo]`、`[quote]`、`[hide]` 等包裹方式，并可选择在末尾**自动追加截图的 `[img]…[/img]`**，一次复制即可用于论坛。
- **复制截图 BBCode**：仅复制所有截图的图床 BBCode。
- **复制原始地址**：复制图床直链（非 BBCode），方便用于 Markdown 或其它站点。
- **下载本次截图**：将本轮生成的截图打包下载到本机。
- 页面下方 **截图展示区** 会展示缩略图，点击可放大查看。

若一次任务产生**多套原盘**结果，在「复制精简媒体信息」时可通过弹窗选择**全部或某一碟**，避免内容混杂。

![获取媒体信息与截图](https://img2.pixhost.to/images/7836/725202305_.gif)

### 4. 右键快捷操作（PC）

在文件列表中对条目 **右键**，无需先展开下方选项即可快捷触发，例如：

- 仅 **获取媒体信息**；
- 仅按固定张数 **截图**（菜单中提供 3 / 5 / 6 / 9 / 10 张等快捷项）；
- **媒体信息 + 截图** 组合快捷执行。

也可与主面板一样使用「设为当前目标」后，在下方勾选选项再点「开始执行」。

### 5. 制作种子（mktorrent）

对**目录或文件**在右键菜单中选择 **「制作种子」**，在弹窗中填写：

- **源路径**（只读展示当前选中项，且须在浏览根目录内）；
- **输出 .torrent 路径或文件名**（可留空由系统按源名称自动命名到种子目录）；
- **Tracker 地址**（每行一个，`http(s)://` 或 `udp://`）；
- **分块大小**（对应 mktorrent 的块大小档位）；
- **私有种子**（适合 PT 规则，默认常勾选）；
- **显示名称、注释**（可选）。

提交后任务在**后台异步**执行，无需一直打开弹窗。左侧 **「种子制作任务」** 面板会显示进行中、已成功、失败或超时数量；可查看进度、终止卡死任务、下载生成的 `.torrent`，或使用 **「清空已完成」** 清理已结束任务及磁盘上的种子文件。

说明摘要：

- 同一源路径在**已有任务进行中**时不可重复提交，避免冲突。
- 单任务默认有**超时时间**（界面提示常见为 240 分钟），超时后由系统结束任务。
- 任务列表会持久化到服务器上的 JSON 文件，**重启服务后仍可查看**；删除任务或清空已完成会同步删除对应 `.torrent` 文件。
- 种子默认保存在服务的输出目录下的 `torrents` 子目录（也可通过配置项 `bdinfo.torrent.store-dir` 指定）。

### 6. 其它功能

- **版本说明**：页眉版本号按钮可打开更新说明。
- **修改账号密码**：登录后通过用户菜单修改，新密码写入服务器凭据文件。
- **移动端主题**：移动布局下可在玻璃、极光、浅色、午夜等主题间切换，便于夜间或户外使用。

