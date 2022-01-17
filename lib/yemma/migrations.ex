defmodule Yemma.Migrations do
  defdelegate change(), to: Yemma.Migrations.CreateUsersTables
end
