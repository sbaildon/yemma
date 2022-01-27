defmodule Yemma.ObanDispatcherTest do
  use Yemma.DataCase

  import Yemma.UsersFixtures

  alias Yemma.Mail.Dispatcher

  @repo YemmaTest.Repo
  @name Oban

  use Oban.Testing, repo: @repo

  setup do
    start_supervised!({Oban, name: @name, repo: @repo, queues: [mailers: 10]})

    conf = start_supervised_yemma!(mail_dispatcher: {Yemma.Mail.ObanDispatcher, oban: @name})

    %{conf: conf, user: user_fixture(conf)}
  end

  describe "deliver_magic_link_instructions/3" do
    test "enqueues a job", %{conf: conf, user: user} do
      token_link = "https://example.com"

      {:ok, %{id: _id}} = Dispatcher.deliver_magic_link_instructions(conf, user, token_link)

      assert {:ok, _} =
               perform_job(
                 Yemma.Mail.ObanDispatcher,
                 %{"user_id" => user.id, "magic_link" => token_link},
                 meta: %{"yemma" => conf.name}
               )
    end
  end
end
