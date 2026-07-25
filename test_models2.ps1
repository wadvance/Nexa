$key = (Get-Content .env | Where-Object { $_ -like 'OPENROUTER_API_KEY=*' }) -replace 'OPENROUTER_API_KEY=',''
$models = @(
  'nvidia/nemotron-3-ultra-550b-a55b:free',
  'openai/gpt-oss-20b:free',
  'google/gemma-4-31b-it:free',
  'inclusionai/ling-3.0-flash:free',
  'poolside/laguna-s-2.1:free',
  'nvidia/nemotron-3-nano-30b-a3b:free',
  'nvidia/nemotron-nano-12b-v2-vl:free'
)

foreach ($model in $models) {
  Write-Host "Testing: $model" -NoNewline
  $body = @{
    model = $model
    messages = @(@{ role='user'; content='Cual es la capital de Francia?' })
    max_tokens = 200
  } | ConvertTo-Json -Compress

  try {
    $r = Invoke-RestMethod -Uri 'https://openrouter.ai/api/v1/chat/completions' `
      -Method Post `
      -Headers @{ Authorization="Bearer $key"; 'Content-Type'='application/json'; 'HTTP-Referer'='https://aetheris.app' } `
      -Body $body -ErrorAction Stop
    Write-Host " -> OK: $($r.choices[0].message.content.Substring(0, [Math]::Min(80, $r.choices[0].message.content.Length)))"
  } catch {
    Write-Host " -> ERROR: $($_.Exception.Response.StatusCode) - $($_.ErrorDetails.Message)"
  }
  Start-Sleep 2
}