defmodule Yemma.Notifiers.NaiveMailer do
  alias Yemma.Notifier
  alias Yemma.Mail.Builder, as: MailBuilder

  @behaviour Notifier

  @impl Notifier
  def deliver_magic_link_instructions(recipient, link, opts) do
    {mailer, builder} = mailer_and_builder(opts)

    MailBuilder.create_magic_link_email(builder, recipient, link)
    |> deliver_with(mailer)
  end

  @impl Notifier
  def deliver_update_email_instructions(recipient, link, opts) do
    {mailer, builder} = mailer_and_builder(opts)

    MailBuilder.create_update_email_instructions(builder, recipient, link)
    |> deliver_with(mailer)
  end

  defp deliver_with(email, mailer) do
    with {:ok, _metadata} <- mailer.deliver(email) do
      {:ok, email}
    end
  end

  defp mailer_and_builder(opts) do
    builder =
      opts[:builder] ||
        raise ArgumentError, """
        #{__MODULE__} needs a :builder to build emails, eg.

        config :my_app, Yemma,
          notifier:
            {Yemma.Notifiers.NaiveMailer,
             mailer: Yemma.Mailer, builder: Yemma.Mail.UnbrandedBuilder}
        """

    mailer =
      opts[:mailer] ||
        raise ArgumentError, """
        #{__MODULE__} needs a :mailer to send emails, eg.

        config :my_app, Yemma,
          notifier:
            {Yemma.Notifiers.ObanMailer,
             mailer: Yemma.Mailer, builder: Yemma.Mail.UnbrandedBuilder}
        """

    {mailer, builder}
  end
end
