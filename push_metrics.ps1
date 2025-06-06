# save as C:\Scripts\push_metrics.ps1
$pushgateway_url = "http://IP_DEL_PUSHGATEWAY:9091/metrics/job/windows_vm/instance/$env:COMPUTERNAME"

$metrics_payload = ""

# Ejemplo de métrica de CPU (necesitas el Get-Counter cmdlet)
# Si no tienes Get-Counter en WS2008, busca alternativas WMI.
try {
    $cpu_usage = (Get-Counter '\Processor(_Total)\% Processor Time').CounterSamples.CookedValue
    $metrics_payload += "# HELP windows_cpu_usage_percent CPU utilization in percent." + "`n"
    $metrics_payload += "# TYPE windows_cpu_usage_percent gauge" + "`n"
    $metrics_payload += "windows_cpu_usage_percent{host=`"$env:COMPUTERNAME`"} $($cpu_usage)" + "`n"
} catch {
    Write-Host "Error getting CPU: $($_.Exception.Message)"
}

# Ejemplo de estado de servicio SNMP (para WS2008)
try {
    $snmp_service = Get-Service -Name "SNMP"
    $service_status = if ($snmp_service.Status -eq "Running") { 1 } else { 0 }
    $metrics_payload += "# HELP windows_snmp_service_status Status of the SNMP service (1=running, 0=stopped)." + "`n"
    $metrics_payload += "# TYPE windows_snmp_service_status gauge" + "`n"
    $metrics_payload += "windows_snmp_service_status{host=`"$env:COMPUTERNAME`"} $($service_status)" + "`n"
} catch {
    Write-Host "Error getting SNMP service status: $($_.Exception.Message)"
}


# Empujar las métricas al Pushgateway
try {
    Invoke-RestMethod -Uri $pushgateway_url -Method Post -Body $metrics_payload -ContentType "text/plain"
    Write-Host "Metrics pushed successfully."
} catch {
    Write-Host "Failed to push metrics: $($_.Exception.Message)"
}