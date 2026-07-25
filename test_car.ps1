$key = $env:OPENROUTER_API_KEY
$body = @{
  model = 'nvidia/nemotron-3-ultra-550b-a55b:free'
  messages = @(@{ role='user'; content='Como cambio el aceite de un carro?' })
  max_tokens = 300
} | ConvertTo-Json -Compress

try {
  $r = Invoke-RestMethod -Uri 'https://openrouter.ai/api/v1/chat/completions' `
    -Method Post `
    -Headers @{ Authorization="Bearer $key"; 'Content-Type'='application/json'; 'HTTP-Referer'='https://aetheris.app' } `
    -Body $body -ErrorAction Stop
  $r.choices[0].message.content
} catch {
  "ERROR: $($_.Exception.Message)"
}
