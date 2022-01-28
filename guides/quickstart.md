# Quickstart

## Installation

1. Install as a dependency in your app<br>
    ```elixir
    # mix.exs
    defp deps do
       [
          ...,
          {:yemma, git: "https://git.sr.ht/~sbaildon/yemma"}
       ]
    end
    ```

1. Fetch and install dependencies<br>
    ```bash
    mix deps.get
    ```

1. Generate migrations for your user and token tables<br>
    ```bash
    mix ecto.gen.migration add_users_tables
    ```

1. Edit your migration file to run the Yemma migrations
    ```elixir
    # priv/repo/migrations/*_add_users_tables.exs
    defmodule MyApp.Repo.Migrations.AddUsersTables do
      use Ecto.Migration

      defdelegate change, to: Yemma.Migrations
    end
    ```

## Usage

1. Create a `User` and `UserToken` module<br>
    ```elixir
    # lib/my_app/user.ex
    defmodule MyApp.User do
      use Yemma.Users.User
    end
    ```

    ```elixir
    # lib/my_app/user_token.ex
    defmodule MyApp.UserToken do
      use Yemma.Users.UserToken
    end
    ```

1. Update your configuration<br>
    ```elixir
    # config/config.exs
    config :my_app, Yemma,
      repo: MyApp.Repo,
      routes: MyAppWeb.Router.Helpers,
      secret_key_base: "Ai3Zg9yLIMInCtRd/8xyJEEVF/Tka5XR3etI6I0g3w5N72R5FEd1q+/xPZXS8HxC",
      user: MyApp.User,
      token: MyApp.UserToken,
      endpoint: MyAppWeb.Endpoint,
    ```

1. Start Yemma with your application
    ```elixir
    # lib/my_app/application.ex
    defmodule MyApp.Application do
      def start(_type, _args) do
        children = [
          ...,
          {Yemma, Application.fetch_env!(:my_app, Yemma)}
        ]
      end
    end
    ```

1. Add Yemma's routes to your web application<br>
    ```elixir
    # lib/my_app_web/router.ex
    defmodule MyAppWeb.Router do
      import Yemma,
        only: [
        redirect_if_user_is_authenticated: 2,
        require_authenticated_user: 2,
        fetch_current_user: 2,
        put_conn_config: 2
        ]
        
      pipeline :browser do
        ...
        plug :fetch_current_user
      end
        
      pipeline :yemma do
        plug :put_conn_config
      end
    
      scope "/", YemmaWeb do
        pipe_through [:yemma, :browser, :redirect_if_user_is_authenticated]

        get "sign_in", UserSessionController, :new
        post "sign_in", UserSessionController, :create

        get "/confirm/:token", UserConfirmationController, :edit
      end
    
      scope "/", YemmaWeb do
        pipe_through [:yemma, :browser, :require_authenticated_user]

        get "/settings", UserSettingsController, :edit
        put "/settings", UserSettingsController, :update
        get "/settings/confirm_email/:token", UserSettingsController, :confirm_email

        delete "/sign_out", UserSessionController, :delete
      end
    
      # Protect routes with :require_authenticated_user
      scope "/protected", MyAppWeb do
        pipe_through [:yemma, :browser, :require_authenticated_user]

        get "/", MyProctedController, :index
      end
    end
    ```
