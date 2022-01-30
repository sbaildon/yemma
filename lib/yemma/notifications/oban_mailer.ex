defmodule Yemma.Notifiers.ObanMailer do
  use Oban.Worker, queue: :mailers
  alias Oban.Job
  alias Yemma.{Notifier}
  alias Yemma.Mail.Builder, as: MailBuilder

  @behaviour Notifier

  @impl Notifier
  def deliver_magic_link_instructions(recipient, link, opts) do
    meta = meta(opts)

    job =
      %{
        user_id: recipient.id,
        magic_link: link
      }
      |> Oban.Job.new(worker: __MODULE__, queue: :mailers, meta: meta)

    Oban.insert(oban(opts), job)
  end

  @impl Notifier
  def deliver_update_email_instructions(recipient, link, opts) do
    meta = meta(opts)

    job =
      %{
        user_id: recipient.id,
        update_email: link
      }
      |> Oban.Job.new(worker: __MODULE__, queue: :mailers, meta: meta)

    Oban.insert(oban(opts), job)
  end

  defp meta(opts) do
    %{yemma: Keyword.get(opts, :yemma, Yemma)}
  end

  defp oban(opts) do
    Keyword.get(opts, :oban, Oban)
  end

  def yemma_to_module(%{"yemma" => name}) when is_binary(name),
    do: String.to_existing_atom(name)

  def yemma_to_module(%{"yemma" => name}) when is_atom(name),
    do: name

  @impl Oban.Worker
  def perform(%Job{
        args: %{"user_id" => user_id, "magic_link" => link},
        meta: meta
      }) do
    with name <- yemma_to_module(meta),
         conf <- Yemma.config(name),
         user <- Yemma.get_user!(conf.name, user_id),
         {mailer, builder} <- mailer_and_builder(conf.notifier) do
      MailBuilder.create_magic_link_email(builder, user, link)
      |> deliver_with(mailer)
    end
  end

  @impl Oban.Worker
  def perform(%Job{
        args: %{"user_id" => user_id, "update_email" => link},
        meta: meta
      }) do
    with name <- yemma_to_module(meta),
         conf <- Yemma.config(name),
         user <- Yemma.get_user!(conf.name, user_id),
         {mailer, builder} <- mailer_and_builder(conf.notifier) do
      MailBuilder.create_update_email_instructions(builder, user, link)
      |> deliver_with(mailer)
    end
  end

  defp deliver_with(email, mailer) do
    with {:ok, _metadata} <- mailer.deliver(email) do
      {:ok, email}
    end
  end

  defp mailer_and_builder({_notifier, opts}) do
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
