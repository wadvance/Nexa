$key = (Get-Content .env | Where-Object { $_ -like 'OPENROUTER_API_KEY=*' }) -replace 'OPENROUTER_API_KEY=',''

$questions = @(
  "Cual es la capital de Panama?",
  "Como cambio una rueda de coche?",
  "Que es la fotosintesis?",
  "Cual es el mejor antibiotico para infeccion de garganta?"
)

foreach ($q in $questions) {
  Write-Host "`n=== Pregunta: $q ==="
  $body = @{
    model = 'nvidia/nemotron-3-ultra-550b-a55b:free'
    messages = @(@{ role='user'; content=$q })
    max_tokens = 300
  } | ConvertTo-Json -Compress

  try {
    $r = Invoke-RestMethod -Uri 'https://openrouter.ai/api/v1/chat/completions' `
      -Method Post `
      -Headers @{ Authorization="Bearer $key"; 'Content-Type'='application/json'; 'HTTP-Referer'='https://aetheris.app' } `
      -Body $body -ErrorAction Stop
    $resp = $r.choices[0].message.content
    Write-Host "Respuesta: $($resp.Substring(0, [Math]::Min(200, $resp.Length)))..."
  } catch {
    Write-Host "ERROR: $($_.Exception.Message)"
  }
  Start-Sleep 2
}