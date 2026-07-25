$key = (Get-Content .env | Where-Object { $_ -like 'OPENROUTER_API_KEY=*' }) -replace 'OPENROUTER_API_KEY=',''
$models = @(
  'google/gemma-2-9b-it:free',
  'qwen/qwen-2.5-7b-instruct:free',
  'deepseek/deepseek-chat-v3-0324:free',
  'meta-llama/llama-3.2-3b-instruct:free',
  'microsoft/phi-3-mini-128k-instruct:free',
  'gryphe/mythomax-l2-13b:free'
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
    Write-Host " -> OK: $($r.choices[0].message.content.Substring(0, [Math]::Min(60, $r.choices[0].message.content.Length)))"
  } catch {
    Write-Host " -> ERROR: $($_.Exception.Response.StatusCode)"
  }
  Start-Sleep 1
}