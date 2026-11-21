# Розгортання стеку на машині з self-hosted runner.
# Запускається з GitHub Actions: powershell -NoProfile -ExecutionPolicy Bypass -File scripts\deploy.ps1
# Потрібні змінні середовища: GH_TOKEN, GH_ACTOR, ENV_FILE, GITHUB_REPOSITORY_OWNER
$ErrorActionPreference = 'Stop'

function Assert-Ok($step) {
    if ($LASTEXITCODE -ne 0) { throw "Крок '$step' завершився з кодом $LASTEXITCODE" }
}

Write-Host '== Вхід у GHCR =='
$env:GH_TOKEN | docker login ghcr.io -u $env:GH_ACTOR --password-stdin
Assert-Ok 'docker login'

$owner = $env:GITHUB_REPOSITORY_OWNER.ToLower()
$env:IMAGE_PREFIX = "ghcr.io/$owner/inclucity"
$env:IMAGE_TAG = 'latest'

Write-Host '== Завантаження нових образів =='
docker compose --env-file $env:ENV_FILE pull backend client
Assert-Ok 'docker compose pull'

Write-Host '== Оновлення контейнерів =='
docker compose --env-file $env:ENV_FILE up -d --remove-orphans --no-build
Assert-Ok 'docker compose up'

Write-Host '== Перевірка працездатності (health) =='
for ($i = 1; $i -le 30; $i++) {
    $status = docker inspect --format '{{.State.Health.Status}}' inclucity-backend 2>$null
    Write-Host "backend health: $status"
    if ($status -eq 'healthy') { Write-Host 'Розгортання успішне'; exit 0 }
    Start-Sleep -Seconds 5
}
docker logs --tail=50 inclucity-backend
throw 'Backend не став healthy'
