API_URL="https://1e6lic5ey5.execute-api.us-east-1.amazonaws.com/prod/auth"


curl -X POST $API_URL \
  -H "Content-Type: application/json" \
  -d '{"cpf": "98765432101"}' \
  -v

curl -X POST $API_URL \
  -H "Content-Type: application/json" \
  -d '{"cpf": ""}' \
  -v

curl -X POST $API_URL \
  -H "Content-Type: application/json" \
  -d '{}' \
  -v