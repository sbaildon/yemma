defmodule Yemma.Notifiers.NaiveMailer do
  alias Yemma.{Config, Notifier}
  alias Yemma.Mail.Builder, as: MailBuilder

  @behaviour Notifier

  @impl Notifier
  def deliver_magic_link_instructions(%Config{} = _conf, recipient, link, opts) do
    MailBuilder.create_magic_link_email(builder!(opts), recipient, link)
    |> deliver_with(opts[:mailer])
  end

  @impl Notifier
  def deliver_update_email_instructions(%Config{} = _conf, recipient, link, opts) do
    MailBuilder.create_update_email_instructions(builder!(opts), recipient, link)
    |> deliver_with(opts[:mailer])
  end

  defp deliver_with(email, mailer) do
    with {:ok, _metadata} <- mailer.deliver(email) do
      {:ok, email}
    end
  end

  defp builder!(opts) do
    opts[:builder] || raise ArgumentError, """
      #{__MODULE__} needs a :builder to build emails, eg.

      config :my_app, Yemma,
        notifier:
          {Yemma.Notifiers.NaiveMailer,
           mailer: Yemma.Mailer, builder: Yemma.Mail.UnbrandedBuilder}
      """
  end
end
