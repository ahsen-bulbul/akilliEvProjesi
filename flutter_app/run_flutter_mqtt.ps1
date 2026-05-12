$envPath = Join-Path $PSScriptRoot "..\backend\.env"

if (-not (Test-Path -LiteralPath $envPath)) {
    Write-Error "backend\.env bulunamadi. Once HiveMQ ayarlarini backend\.env dosyasina ekleyin."
    exit 1
}

$config = @{}
Get-Content -LiteralPath $envPath | ForEach-Object {
    if ($_ -notmatch "^\s*#" -and $_ -match "=") {
        $key, $value = $_ -split "=", 2
        $config[$key.Trim()] = $value.Trim().Trim('"').Trim("'")
    }
}

$requiredKeys = @(
    "SUPABASE_URL",
    "SUPABASE_ANON_KEY",
    "MQTT_BROKER",
    "MQTT_PORT",
    "MQTT_USERNAME",
    "MQTT_PASSWORD",
    "MQTT_TOPIC",
    "MQTT_TLS"
)
foreach ($key in $requiredKeys) {
    if (-not $config.ContainsKey($key) -or [string]::IsNullOrWhiteSpace($config[$key])) {
        Write-Error "$key backend\.env icinde eksik."
        exit 1
    }
}

$flutterCommand = Get-Command flutter -ErrorAction SilentlyContinue
if (-not $flutterCommand) {
    Write-Error "flutter komutu bulunamadi. Flutter bin klasorunu PATH'e ekleyin."
    exit 1
}

$flutterExe = $flutterCommand.Source
$definesPath = Join-Path $PSScriptRoot ".dart_define_mqtt.json"
$defines = [ordered]@{
    SUPABASE_URL = $config["SUPABASE_URL"]
    SUPABASE_ANON_KEY = $config["SUPABASE_ANON_KEY"]
    MQTT_BROKER = $config["MQTT_BROKER"]
    MQTT_PORT = $config["MQTT_PORT"]
    MQTT_USERNAME = $config["MQTT_USERNAME"]
    MQTT_PASSWORD = $config["MQTT_PASSWORD"]
    MQTT_TOPIC = $config["MQTT_TOPIC"]
    MQTT_TLS = $config["MQTT_TLS"]
}
$defines | ConvertTo-Json | Set-Content -LiteralPath $definesPath -Encoding UTF8

$args = @("run", "--dart-define-from-file=$definesPath")

Write-Host "Flutter: $flutterExe"
Write-Host "Supabase URL: $($config["SUPABASE_URL"])"
Write-Host "MQTT broker: $($config["MQTT_BROKER"])"
Write-Host "MQTT topic: $($config["MQTT_TOPIC"])"
Write-Host "Dart defines: $definesPath"

& $flutterExe @args
