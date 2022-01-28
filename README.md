# Yemma

Opinionated, passwordless authentication for Elixir projects

## Testing

1. Start a postgres database  
`docker run --rm --name yemma_testing -e POSTGRES_PASSWORD=password -p 127.0.0.1:5432:5432 -d postgres`

1. Copy and optionally update `DATABASE_URL`  
`cp env{.example,}`

1. Set up the database  
`make test-setup`

1. Run tests  
`make test`
