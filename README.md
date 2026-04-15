# BDInfo

手动编译 https://github.com/dotnetcorecorner/BDInfo 项目的arm64架构的版本

# BDInfo

可在多平台上扫描蓝光光盘（全高清、超高清、3D）。提供的二进制文件为便携版，无需安装任何运行框架。

## 命令参数

| 短参数 | 长参数 | 说明 | 必填 | 默认值 |
| --- | --- | --- | --- | --- |
| _`-p`_ | _`--path`_ | ISO 文件或蓝光文件夹路径	 | x |  |
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
| _`-p`_ | _`--path`_ | ISO 文件路径 | x |
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



