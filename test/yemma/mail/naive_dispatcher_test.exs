defmodule Yemma.NaiveDispatcherTest do
  use Yemma.DataCase

  import Yemma.UsersFixtures

  alias Yemma.Mail.Dispatcher

  setup do
    conf = yemma_config(mail_dispatcher: Yemma.Mail.NaiveDispatcher)
    %{conf: conf, user: user_fixture(conf)}
  end

  describe "deliver_magic_link_instructions/3" do
    test "delivers mail", %{conf: conf, user: user} do
      token_link = "https://example.com"

      {:ok, %{text_body: text_body, html_body: html_body}} =
        Dispatcher.deliver_magic_link_instructions(conf, user, token_link)

      assert String.contains?(text_body, token_link)
      assert String.contains?(html_body, token_link)
    end
  end
end
