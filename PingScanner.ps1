# ===============================
#   PowerShell 5.1 Ping 扫描器
#   高速 + 汇总通 IP + 保持窗口
# ===============================

$default = "192.168.31"
$subnet = Read-Host "请输入三级网段 (默认: $default)"
if ([string]::IsNullOrWhiteSpace($subnet)) { $subnet = $default }

Write-Host "`n===== 开始高速扫描 ====="
Write-Host "扫描网段：$subnet.1 ~ $subnet.255`n"

# 限制最大线程数
$MaxThreads = 50
$RunspacePool = [runspacefactory]::CreateRunspacePool(1, $MaxThreads)
$RunspacePool.Open()

$Jobs = @()
$LiveIPs = @()   # 存储通了的 IP

# 多线程脚本
$ThreadScript = {
    param($ip)
    $output = ping.exe -n 1 -w 200 $ip
    $OK = $output -match "TTL="
    return @{
        IP = $ip
        OK = $OK
    }
}

# 创建线程任务
foreach ($i in 1..255) {
    $ip = "$subnet.$i"

    $ps = [powershell]::Create()
    $ps.RunspacePool = $RunspacePool
    $null = $ps.AddScript($ThreadScript).AddArgument($ip)
    $handle = $ps.BeginInvoke()

    $Jobs += [pscustomobject]@{
        Handle = $handle
        PS     = $ps
    }
}

# 处理扫描结果
foreach ($job in $Jobs) {
    $result = $job.PS.EndInvoke($job.Handle)
    if ($result.OK) {
        Write-Host "$($result.IP) 通了" -ForegroundColor Green
        $LiveIPs += $result.IP
    } else {
        Write-Host "$($result.IP) 不通" -ForegroundColor Red
    }
    $job.PS.Dispose()
}

$RunspacePool.Close()
$RunspacePool.Dispose()

# 输出通了的 IP 汇总
Write-Host "`n===== 扫描完成，通的 IP 列表 =====" -ForegroundColor Cyan
if ($LiveIPs.Count -eq 0) {
    Write-Host "没有通的 IP。" -ForegroundColor Yellow
} else {
    $LiveIPs | ForEach-Object { Write-Host $_ -ForegroundColor Green }
}

Write-Host "`n扫描结束." -ForegroundColor Cyan

# ===============================
# 保持窗口不关闭（鼠标右键运行时）
# ===============================
Read-Host "按回车键退出..."
