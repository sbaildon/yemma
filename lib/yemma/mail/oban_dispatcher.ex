defmodule Yemma.Mail.ObanDispatcher do
  use Oban.Worker, queue: :mailers
  alias Oban.Job
  alias Yemma.{Mailer, Config}
  alias Yemma.Users.User
  alias Yemma.Mail.Dispatcher, as: MailDispatcher

  @behaviour MailDispatcher

  @impl MailDispatcher
  def deliver_magic_link_instructions(%Config{} = conf, %User{} = recipient, link) do
    job =
      Yemma.Mail.ObanDispatcher.new(
        %{
          user_id: recipient.id,
          link: link
        },
        meta: %{
          yemma: conf.name
        }
      )

    Oban.insert(conf.oban, job)
  end

  @impl Oban.Worker
  def perform(%Job{args: %{"user_id" => user_id, "magic_link" => link}, meta: %{"yemma" => name}}) do
    with conf <- Yemma.config(name),
         user <- Yemma.get_user!(conf.name, user_id) do
      conf.mail_builder.create_magic_link_email(conf, user, link)
      |> Mailer.deliver()
    end
  end
end
