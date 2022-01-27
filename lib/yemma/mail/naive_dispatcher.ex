defmodule Yemma.Mail.NaiveDispatcher do
  alias Yemma.{Config}
  alias Yemma.Mail.Builder, as: MailBuilder
  alias Yemma.Mail.Dispatcher, as: MailDispatcher

  @behaviour MailDispatcher

  @impl MailDispatcher
  def deliver_magic_link_instructions(%Config{} = conf, recipient, link, _opts) do
    MailBuilder.create_magic_link_email(conf, recipient, link)
    |> deliver(conf)
  end

  @impl MailDispatcher
  def deliver_update_email_instructions(%Config{} = conf, recipient, link, _opts) do
    MailBuilder.create_update_email_instructions(conf, recipient, link)
    |> deliver(conf)
  end

  defp deliver(email, conf) do
    with {:ok, _metadata} <- conf.mailer.deliver(email) do
      {:ok, email}
    end
  end
end
