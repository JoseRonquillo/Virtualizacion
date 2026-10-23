# Ejecutar como Administrador desde la raiz del repo, despues de cada reinicio de Windows.
$ErrorActionPreference = "Stop"
$repo   = Split-Path $PSScriptRoot -Parent
$mkip   = (minikube ip).Trim()
$prefix = ($mkip -split '\.')[0..2] -join '.'

$pool = @"
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: pool-jarm
  namespace: metallb-system
spec:
  addresses:
  - ${prefix}.200-${prefix}.210
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: l2-jarm
  namespace: metallb-system
spec:
  ipAddressPools:
  - pool-jarm
"@

$poolFile = Join-Path $repo "metallb\ip-pool.yaml"
[System.IO.File]::WriteAllText($poolFile, $pool, (New-Object System.Text.UTF8Encoding $false))
kubectl apply -f $poolFile

# Esperar a que Traefik reciba su IP de MetalLB
$ip = ""
for ($i = 0; $i -lt 30 -and -not $ip; $i++) {
    $ip = kubectl get svc traefik -n traefik -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
    if (-not $ip) { Start-Sleep -Seconds 2 }
}
if (-not $ip) { throw "Traefik no recibio IP de MetalLB" }
Write-Host "IP de Traefik (MetalLB): $ip"

# Ruta estatica hacia la IP de MetalLB (necesaria con Hyper-V; no persiste tras reiniciar)
Remove-NetRoute -DestinationPrefix "$ip/32" -Confirm:$false -ErrorAction SilentlyContinue
New-NetRoute -DestinationPrefix "$ip/32" -InterfaceAlias "vEthernet (Default Switch)" -NextHop $mkip -PolicyStore ActiveStore | Out-Null
Write-Host "Ruta agregada: $ip -> $mkip"

# Actualizar el archivo hosts (con reintentos por si otro proceso lo bloquea)
$hostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"
$names = "argocd.jarm.local", "grafana.jarm.local", "prometheus.jarm.local"
$lines = @(Get-Content $hostsPath | Where-Object { $_ -notmatch 'jarm\.local' })
$lines += $names | ForEach-Object { "$ip $_" }

$ok = $false
for ($i = 1; $i -le 10 -and -not $ok; $i++) {
    try {
        Set-Content -Path $hostsPath -Value $lines -Encoding ascii -ErrorAction Stop
        $ok = $true
    } catch {
        Write-Host "hosts bloqueado, reintento $i/10..."
        Start-Sleep -Seconds 2
    }
}
if (-not $ok) { throw "No se pudo escribir hosts. Editalo manualmente (ver README)." }
Write-Host "hosts actualizado:"
Get-Content $hostsPath | Select-String "jarm.local"