defmodule Yemma.Mail.Dispatcher do
  alias Yemma.Config
  alias Yemma.Users.User

  @type conf :: Config.t()
  @type user :: map()
  @type link :: String.t()

  @callback deliver_magic_link_instructions(conf(), user(), link()) ::
              {:ok, any()} | {:error, any()}

  def deliver_magic_link_instructions(%Config{} = conf, %User{} = user, link) do
    conf.mail_dispatcher.deliver_magic_link_instructions(conf, user, link)
  end
end
