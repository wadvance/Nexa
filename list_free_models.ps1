$key = (Get-Content .env | Where-Object { $_ -like 'OPENROUTER_API_KEY=*' }) -replace 'OPENROUTER_API_KEY=',''
$r = Invoke-RestMethod -Uri 'https://openrouter.ai/api/v1/models' -Headers @{ Authorization="Bearer $key" }
$r.data | Where-Object { $_.id -like '*:free' } | Select-Object id, name | Format-Table -AutoSize