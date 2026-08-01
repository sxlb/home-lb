<#
.SYNOPSIS
    無名の主页 · Windows PowerShell 部署脚本
.DESCRIPTION
    在 Windows 上构建前端、启动 admin-server、托管静态站点
    适用于本地开发预览 / 局域网 Windows 服务器部署
.EXAMPLE
    .\deploy.ps1 deploy
    完整部署：构建前端 + 启动 admin-server + 启动静态服务器
.EXAMPLE
    .\deploy.ps1 build
    仅构建前端
.EXAMPLE
    .\deploy.ps1 start
    启动所有服务（admin-server + 静态服务器）
.EXAMPLE
    .\deploy.ps1 stop
    停止所有服务
.EXAMPLE
    .\deploy.ps1 -DryRun deploy
    试运行：只打印命令不执行
#>
[CmdletBinding()]
param(
    [Parameter(Position=0)]
    [ValidateSet('deploy','build','start','stop','restart','status','health','clean','help')]
    [string]$Command = 'help',

    # Web 端口（静态服务器）
    [int]$WebPort = 8080,
    # admin-server 端口
    [int]$AdminPort = 12446,
    # admin-server 鉴权 token
    [string]$AdminToken = "",
    # 是否以生产模式构建（启用 terser 压缩等）
    [bool]$Production = $true,
    # 试运行
    [switch]$DryRun,
    # 静态服务器工具：http-server / serve
    [ValidateSet('http-server','serve')]
    [string]$StaticServer = 'http-server'
)

$ErrorActionPreference = 'Stop'
Set-Location -Path $PSScriptRoot/..

# ============== 颜色与日志 ==============
function Write-Log   { param([string]$Msg) Write-Host "[$(Get-Date -Format 'HH:mm:ss')] $Msg" -ForegroundColor Green }
function Write-Warn  { param([string]$Msg) Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [WARN] $Msg" -ForegroundColor Yellow }
function Write-Err   { param([string]$Msg) Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [ERROR] $Msg" -ForegroundColor Red }
function Write-Info  { param([string]$Msg) Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [INFO] $Msg" -ForegroundColor Cyan }

function Invoke-Run {
    param([scriptblock]$Block, [string]$Desc)
    if ($DryRun) {
        Write-Host "[DRY-RUN] $Desc" -ForegroundColor Magenta
        return
    }
    try {
        & $Block
    } catch {
        Write-Err "$Desc 失败：$_"
        throw
    }
}

# ============== 环境检查 ==============
function Test-Command {
    param([string]$Name)
    $null -ne (Get-Command $Name -ErrorAction SilentlyContinue)
}

function Install-NodeDeps {
    Write-Log "==== 检查 Node.js 与包管理器 ===="
    if (-not (Test-Command 'node')) {
        Write-Err "未检测到 Node.js，请先安装 Node.js 20+：https://nodejs.org/"
        throw "Node.js 未安装"
    }
    $nodeVer = node -v
    Write-Info "Node.js: $nodeVer"

    if (-not (Test-Command 'pnpm')) {
        Write-Warn "未检测到 pnpm，正在通过 corepack 启用..."
        Invoke-Run { corepack enable } "启用 corepack"
        Invoke-Run { corepack prepare pnpm@10 --activate } "准备 pnpm 10"
    }
    $pnpmVer = pnpm -v
    Write-Info "pnpm: $pnpmVer"
}

function Install-StaticServer {
    if ($StaticServer -eq 'http-server') {
        if (-not (Test-Command 'http-server')) {
            Write-Warn "未检测到 http-server，正在全局安装..."
            Invoke-Run { npm install -g http-server } "安装 http-server"
        }
    } else {
        if (-not (Test-Command 'serve')) {
            Write-Warn "未检测到 serve，正在全局安装..."
            Invoke-Run { npm install -g serve } "安装 serve"
        }
    }
}

# ============== 项目准备 ==============
function Initialize-Env {
    Write-Log "==== 检查 .env ===="
    if (-not (Test-Path ".env")) {
        Write-Warn ".env 不存在，从 .env.example 复制"
        Invoke-Run { Copy-Item ".env.example" ".env" } "复制 .env"
        Write-Warn "请编辑 .env 修改配置后再次运行"
    }
}

function Initialize-RuntimeConfig {
    Write-Log "==== 检查 runtime-config.json ===="
    $rcPath = "public/runtime-config.json"
    if (-not (Test-Path $rcPath)) {
        Write-Warn "$rcPath 不存在，创建空配置"
        Invoke-Run { '{}' | Out-File -FilePath $rcPath -Encoding utf8 } "创建 $rcPath"
    }
}

# ============== 构建 ==============
function Build-Frontend {
    Write-Log "==== 构建前端 ===="
    Invoke-Run { pnpm install --frozen-lockfile } "安装依赖"
    if ($Production) {
        Invoke-Run { pnpm run build } "构建（生产模式）"
    } else {
        Invoke-Run { pnpm run build } "构建"
    }
    if (-not (Test-Path "dist")) {
        throw "构建失败：dist 目录不存在"
    }
    $size = (Get-ChildItem -Recurse dist | Measure-Object -Property Length -Sum).Sum / 1MB
    Write-Info ("dist/ 大小: {0:N2} MB" -f $size)
}

# ============== 服务管理 ==============
$script:adminProcess = $null
$script:staticProcess = $null

function Start-AdminServer {
    Write-Log "==== 启动 admin-server ===="
    Push-Location "admin-server"
    try {
        if (-not (Test-Path "node_modules")) {
            Invoke-Run { npm install --omit=dev } "安装 admin-server 依赖"
        }
    } finally { Pop-Location }

    # 准备环境变量
    $env:PORT = $AdminPort
    $env:PROJECT_ROOT = (Resolve-Path ".").Path
    if ($AdminToken) { $env:ADMIN_TOKEN = $AdminToken }

    if ($DryRun) {
        Write-Host "[DRY-RUN] node admin-server/server.js (PORT=$AdminPort)" -ForegroundColor Magenta
        return
    }

    # 后台启动 admin-server
    $script:adminProcess = Start-Process -FilePath "node" -ArgumentList "admin-server/server.js" `
        -WorkingDirectory (Resolve-Path "admin-server") `
        -PassThru -NoNewWindow `
        -RedirectStandardOutput "admin-server/admin.out.log" `
        -RedirectStandardError "admin-server/admin.err.log"
    Start-Sleep -Seconds 1
    if ($script:adminProcess.HasExited) {
        throw "admin-server 启动失败，查看日志：admin-server/admin.err.log"
    }
    Write-Info "admin-server PID: $($script:adminProcess.Id)，端口 $AdminPort"

    # 保存 PID
    $script:adminProcess.Id | Out-File ".admin.pid" -Encoding ascii
}

function Start-StaticServer {
    Write-Log "==== 启动静态服务器 ===="
    if ($DryRun) {
        Write-Host "[DRY-RUN] $StaticServer dist -p $WebPort" -ForegroundColor Magenta
        return
    }

    if ($StaticServer -eq 'http-server') {
        $script:staticProcess = Start-Process -FilePath "http-server" `
            -ArgumentList "dist","-p",$WebPort,"-g" `
            -WorkingDirectory (Resolve-Path ".") `
            -PassThru -NoNewWindow `
            -RedirectStandardOutput "static.out.log" `
            -RedirectStandardError "static.err.log"
    } else {
        $script:staticProcess = Start-Process -FilePath "serve" `
            -ArgumentList "dist","-l",$WebPort `
            -WorkingDirectory (Resolve-Path ".") `
            -PassThru -NoNewWindow `
            -RedirectStandardOutput "static.out.log" `
            -RedirectStandardError "static.err.log"
    }
    Start-Sleep -Seconds 1
    if ($script:staticProcess.HasExited) {
        throw "静态服务器启动失败，查看日志：static.err.log"
    }
    Write-Info "静态服务器 PID: $($script:staticProcess.Id)，端口 $WebPort"

    $script:staticProcess.Id | Out-File ".static.pid" -Encoding ascii
}

function Stop-Services {
    Write-Log "==== 停止服务 ===="
    # 优先用 PID 文件
    foreach ($pidFile in @(".admin.pid", ".static.pid")) {
        if (Test-Path $pidFile) {
            $procId = Get-Content $pidFile -ErrorAction SilentlyContinue
            if ($procId) {
                try {
                    Stop-Process -Id $procId -Force -ErrorAction Stop
                    Write-Info "已停止 PID $procId"
                } catch {
                    Write-Warn "PID $procId 已不存在"
                }
            }
            Remove-Item $pidFile -Force
        }
    }
    # 兜底：按端口杀进程
    foreach ($port in @($AdminPort, $WebPort)) {
        $conns = Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue
        foreach ($conn in $conns) {
            try {
                Stop-Process -Id $conn.OwningProcess -Force -ErrorAction Stop
                Write-Warn "按端口 $port 终止 PID $($conn.OwningProcess)"
            } catch {}
        }
    }
}

function Get-ServiceStatus {
    Write-Log "==== 服务状态 ===="
    # admin-server
    $adminRunning = $false
    if (Test-Path ".admin.pid") {
        $procId = Get-Content .admin.pid
        $proc = Get-Process -Id $procId -ErrorAction SilentlyContinue
        if ($proc) {
            $adminRunning = $true
            Write-Info "admin-server: 运行中 (PID $procId)"
        }
    }
    if (-not $adminRunning) {
        Write-Warn "admin-server: 未运行"
    }

    # 静态服务器
    $staticRunning = $false
    if (Test-Path ".static.pid") {
        $procId = Get-Content .static.pid
        $proc = Get-Process -Id $procId -ErrorAction SilentlyContinue
        if ($proc) {
            $staticRunning = $true
            Write-Info "静态服务器: 运行中 (PID $procId)"
        }
    }
    if (-not $staticRunning) {
        Write-Warn "静态服务器: 未运行"
    }
}

function Test-Health {
    Write-Log "==== 健康检查 ===="
    try {
        $resp = Invoke-WebRequest "http://127.0.0.1:$WebPort/" -UseBasicParsing -TimeoutSec 5
        if ($resp.StatusCode -eq 200) {
            Write-Info "主站正常：http://127.0.0.1:$WebPort/"
        } else {
            Write-Warn "主站响应异常：$($resp.StatusCode)"
        }
    } catch {
        Write-Err "主站访问失败：$_"
    }
    try {
        $resp = Invoke-WebRequest "http://127.0.0.1:$AdminPort/api/all" -UseBasicParsing -TimeoutSec 5
        if ($resp.StatusCode -eq 200) {
            Write-Info "admin-server API 正常"
        } else {
            Write-Warn "admin-server API 响应异常：$($resp.StatusCode)"
        }
    } catch {
        Write-Warn "admin-server API 访问失败（若启用鉴权属正常）"
    }
}

# ============== 完整部署 ==============
function Invoke-FullDeploy {
    Write-Log "############ 开始完整部署 ############"
    Install-NodeDeps
    Install-StaticServer
    Stop-Services
    Initialize-Env
    Initialize-RuntimeConfig
    Build-Frontend
    Start-AdminServer
    Start-StaticServer
    Test-Health
    Write-Log "############ 部署完成 ############"
    Write-Info "主站地址:    http://localhost:$WebPort/"
    Write-Info "管理后台地址: http://localhost:$WebPort/admin (若 admin-server 同机)"
    Write-Info "管理后台直连: http://localhost:$AdminPort/admin"
    if ($AdminToken) {
        Write-Info "鉴权已启用，访问 /api 需带 X-Admin-Token: $AdminToken"
    } else {
        Write-Warn "未设置 -AdminToken，管理后台无鉴权！"
    }
}

# ============== 清理 ==============
function Remove-Build {
    Write-Log "==== 清理构建产物 ===="
    foreach ($p in @("dist",".admin.pid",".static.pid","admin-server/admin.out.log","admin-server/admin.err.log","static.out.log","static.err.log")) {
        if (Test-Path $p) {
            Invoke-Run { Remove-Item $p -Recurse -Force } "删除 $p"
        }
    }
    Write-Info "已清理"
}

# ============== 帮助 ==============
function Show-Help {
    Write-Host @"
無名の主页 · Windows PowerShell 部署脚本

用法:
    .\deploy.ps1 <命令> [选项]

命令:
    deploy     完整部署（推荐首次使用）
    build      仅构建前端
    start      启动所有服务
    stop       停止所有服务
    restart    重启所有服务
    status     查看服务状态
    health     健康检查
    clean      清理构建产物与日志
    help       显示此帮助

选项:
    -WebPort <int>          静态服务器端口 (默认: 8080)
    -AdminPort <int>        admin-server 端口 (默认: 12446)
    -AdminToken <string>    管理后台鉴权 token
    -Production <bool>      生产模式构建 (默认: true)
    -StaticServer <name>    静态服务器: http-server / serve (默认: http-server)
    -DryRun                 试运行，只打印不执行

示例:
    # 1. 完整部署
    .\deploy.ps1 deploy

    # 2. 自定义端口与鉴权
    .\deploy.ps1 deploy -WebPort 80 -AdminPort 9000 -AdminToken "my-secret"

    # 3. 仅构建
    .\deploy.ps1 build

    # 4. 重启
    .\deploy.ps1 restart

    # 5. 试运行
    .\deploy.ps1 deploy -DryRun
"@
}

# ============== 入口 ==============
switch ($Command) {
    'deploy'  { Invoke-FullDeploy }
    'build'   { Install-NodeDeps; Initialize-Env; Initialize-RuntimeConfig; Build-Frontend }
    'start'   { Start-AdminServer; Start-StaticServer }
    'stop'    { Stop-Services }
    'restart' { Stop-Services; Start-AdminServer; Start-StaticServer }
    'status'  { Get-ServiceStatus }
    'health'  { Test-Health }
    'clean'   { Stop-Services; Remove-Build }
    'help'    { Show-Help }
    default   { Show-Help }
}
