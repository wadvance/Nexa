$key = (Get-Content .env | Where-Object { $_ -like 'OPENROUTER_API_KEY=*' }) -replace 'OPENROUTER_API_KEY=',''
$body = @{
  model = 'google/gemma-4-26b-a4b-it:free'
  messages = @(@{ role='user'; content='Cual es la capital de Francia?' })
  max_tokens = 200
} | ConvertTo-Json -Compress

try {
  $r = Invoke-RestMethod -Uri 'https://openrouter.ai/api/v1/chat/completions' `
    -Method Post `
    -Headers @{ Authorization="Bearer $key"; 'Content-Type'='application/json'; 'HTTP-Referer'='https://aetheris.app' } `
    -Body $body -ErrorAction Stop
  $r.choices[0].message.content
} catch {
  "ERROR: $($_.Exception.Response.StatusCode) $($_.ErrorDetails.Message)"
}