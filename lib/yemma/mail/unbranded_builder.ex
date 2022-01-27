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

  @impl Builder
  def create_update_email_instructions(%{email: email}, link) do
    base_email()
    |> subject("Update email instructions")
    |> to(email)
    |> text_body("""
    Update your email by visiting the link below:

    #{link}

    If you didn't request this change, please ignore this
    """)
    |> html_body("""
    <p>Update your email by visiting the link below:</p>
    <br>
    <a href="#{link}">Update email</a>
    """)
  end

  defp base_email do
    new()
    |> from("something@yemma.test")
  end
end
