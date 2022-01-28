defmodule Yemma.Notifiers.ObanMailer do
  use Oban.Worker, queue: :mailers
  alias Oban.Job
  alias Yemma.{Config, Notifier}
  alias Yemma.Mail.Builder, as: MailBuilder

  @behaviour Notifier

  @impl Notifier
  def deliver_magic_link_instructions(%Config{} = conf, recipient, link, opts) do
    meta = meta(conf.name, opts[:mailer], opts[:builder])

    job =
      %{
        user_id: recipient.id,
        magic_link: link
      }
      |> Oban.Job.new(worker: __MODULE__, queue: :mailers, meta: meta)

    Oban.insert(opts[:oban], job)
  end

  @impl Notifier
  def deliver_update_email_instructions(%Config{} = conf, recipient, link, opts) do
    meta = meta(conf.name, opts[:mailer], opts[:builder])

    job =
      %{
        user_id: recipient.id,
        update_email: link
      }
      |> Oban.Job.new(worker: __MODULE__, queue: :mailers, meta: meta)

    Oban.insert(opts[:oban], job)
  end

  defp meta(yemma, mailer, builder) do
    %{yemma: yemma, mailer: mailer, builder: builder}
  end

  @impl Oban.Worker
  def perform(%Job{
        args: %{"user_id" => user_id, "magic_link" => link},
        meta: %{"yemma" => name, "mailer" => mailer, "builder" => builder}
      }) do
    with conf <- Yemma.config(name),
         user <- Yemma.get_user!(conf.name, user_id) do
      MailBuilder.create_magic_link_email(builder, user, link)
      |> deliver_with(mailer)
    end
  end

  @impl Oban.Worker
  def perform(%Job{
        args: %{"user_id" => user_id, "update_email" => link},
        meta: %{"yemma" => name, "mailer" => mailer, "builder" => builder}
      }) do
    with conf <- Yemma.config(name),
         user <- Yemma.get_user!(conf.name, user_id) do
      MailBuilder.create_update_email_instructions(builder, user, link)
      |> deliver_with(mailer)
    end
  end

  defp deliver_with(email, mailer) do
    with {:ok, _metadata} <- mailer.deliver(email) do
      {:ok, email}
    end
  end
end
