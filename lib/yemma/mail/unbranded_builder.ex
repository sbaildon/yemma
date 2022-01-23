defmodule Yemma.Mail.UnbrandedBuilder do
  @behaviour Yemma.Mail.Builder

  import Swoosh.Email
  alias Yemma.Mail.Builder

  @impl Builder
  def create_magic_link_email(%{email: email}, link) do
    base_email()
    |> subject("Sign in link")
    |> to(email)
    |> text_body("""
      Sign in with your magic link

      #{link}
    """)
    |> html_body("""
      <p>Sign in with your magic link</p>
      <a href="#{link}">Sign in</a>
    """)
  end

  defp base_email do
    new()
    |> from("something@yemma.test")
  end
end
