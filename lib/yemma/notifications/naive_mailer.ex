defmodule Yemma.Notifiers.NaiveMailer do
  alias Yemma.{Config, Notifier}
  alias Yemma.Mail.Builder, as: MailBuilder

  @behaviour Notifier

  @impl Notifier
  def deliver_magic_link_instructions(%Config{} = conf, recipient, link, opts) do
    MailBuilder.create_magic_link_email(conf, recipient, link)
    |> deliver_with(opts[:mailer])
  end

  @impl Notifier
  def deliver_update_email_instructions(%Config{} = conf, recipient, link, opts) do
    MailBuilder.create_update_email_instructions(conf, recipient, link)
    |> deliver_with(opts[:mailer])
  end

  defp deliver_with(email, mailer) do
    with {:ok, _metadata} <- mailer.deliver(email) do
      {:ok, email}
    end
  end
end
