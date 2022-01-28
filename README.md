# Yemma

Opinionated, passwordless authentication for Elixir projects

## Getting started

See the [quickstart guide](guides/quicksstart.md)

## Testing

1. Start a postgres database<br>
    ```shell
    docker run --rm --name yemma_testing -e POSTGRES_PASSWORD=password -p 127.0.0.1:5432:5432 -d postgres
    ```

1. Copy and optionally update `DATABASE_URL`<br>
    ```shell
    cp env{.example,}
    ```

1. Set up the database<br>
    ```shell
    make test-setup
    ```

1. Run tests<br>
    ```shell
    make test
    ```
