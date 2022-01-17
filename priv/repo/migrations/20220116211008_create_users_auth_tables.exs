defmodule Yemma.Repo.Migrations.CreateUsersTables do
  use Ecto.Migration
  defdelegate change(), to: Yemma.Migrations.CreateUsersTables
end
