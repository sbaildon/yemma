defmodule Yemma.Mail.NaiveDispatcher do
  alias Yemma.{Mailer, Config}
  alias Yemma.Users.User
  alias Yemma.Mail.Builder, as: MailBuilder
  alias Yemma.Mail.Dispatcher, as: MailDispatcher

  @behaviour MailDispatcher
  def deliver_magic_link_instructions(%Config{} = conf, %User{} = recipient, link) do
    MailBuilder.create_magic_link_email(conf, recipient, link)
    |> deliver()
  end

  defp deliver(email) do
    with {:ok, _metadata} <- Mailer.deliver(email) do
      {:ok, email}
    end
  end
end
