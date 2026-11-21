# Deploy the stack on the machine that hosts the self-hosted runner.
# Called from GitHub Actions: powershell -NoProfile -ExecutionPolicy Bypass -File scripts\deploy.ps1
# Required environment variables: GH_TOKEN, GH_ACTOR, ENV_FILE, GITHUB_REPOSITORY_OWNER
# NOTE: keep this file ASCII-only - Windows PowerShell 5.1 reads BOM-less UTF-8 as ANSI.
$ErrorActionPreference = 'Stop'

function Assert-Ok($step) {
    if ($LASTEXITCODE -ne 0) { throw "Step '$step' failed with exit code $LASTEXITCODE" }
}

Write-Host '== Login to GHCR =='
$env:GH_TOKEN | docker login ghcr.io -u $env:GH_ACTOR --password-stdin
Assert-Ok 'docker login'

$owner = $env:GITHUB_REPOSITORY_OWNER.ToLower()
$env:IMAGE_PREFIX = "ghcr.io/$owner/inclucity"
$env:IMAGE_TAG = 'latest'

Write-Host '== Pull new images =='
docker compose --env-file $env:ENV_FILE pull backend client
Assert-Ok 'docker compose pull'

Write-Host '== Update containers =='
docker compose --env-file $env:ENV_FILE up -d --remove-orphans --no-build
Assert-Ok 'docker compose up'

Write-Host '== Health check =='
for ($i = 1; $i -le 30; $i++) {
    $status = docker inspect --format '{{.State.Health.Status}}' inclucity-backend 2>$null
    Write-Host "backend health: $status"
    if ($status -eq 'healthy') { Write-Host 'Deploy successful'; exit 0 }
    Start-Sleep -Seconds 5
}
docker logs --tail=50 inclucity-backend
throw 'Backend did not become healthy'
