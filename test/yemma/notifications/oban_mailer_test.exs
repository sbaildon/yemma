defmodule Yemma.Notifiers.ObanMailerTest do
  use Yemma.DataCase

  import Yemma.UsersFixtures

  alias Yemma.Notifier

  @repo YemmaTest.Repo
  @name Oban

  use Oban.Testing, repo: @repo

  setup do
    start_supervised!({Oban, name: @name, repo: @repo, queues: [mailers: 10]})

    conf =
      start_supervised_yemma!(
        notifier: {Yemma.Notifiers.ObanMailer, oban: @name, mailer: Yemma.Mailer, builder: Yemma.Mail.UnbrandedBuilder}
      )

    %{conf: conf, user: user_fixture(conf)}
  end

  describe "deliver_magic_link_instructions/3" do
    test "enqueues a job", %{conf: conf, user: user} do
      token_link = "https://example.com"

      {:ok, %{id: _id}} = Notifier.deliver_magic_link_instructions(conf, user, token_link)

      assert {:ok, _} =
               perform_job(
                 Yemma.Notifiers.ObanMailer,
                 %{"user_id" => user.id, "magic_link" => token_link},
                 meta: %{"yemma" => conf.name, "mailer" => Yemma.Mailer, "builder" => Yemma.Mail.UnbrandedBuilder}
               )
    end
  end
end
