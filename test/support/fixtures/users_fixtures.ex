defmodule Yemma.UsersFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Yemma.Users` context.
  """

  def unique_user_email, do: "user#{System.unique_integer()}@example.com"

  def valid_user_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      email: unique_user_email()
    })
  end

  def user_fixture(conf, attrs \\ %{}) do
    attrs = attrs |> valid_user_attributes()

    {:ok, user} = Yemma.Users.register_user(conf, attrs)

    user
  end

  def extract_user_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end
end
