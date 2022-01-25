defmodule Yemma.Mail.Builder do
  alias Yemma.Config

  @type conf :: Config.t()
  @type user :: map()
  @type link :: String.t()

  @callback create_magic_link_email(user(), link()) :: Swoosh.Email.t()

  def create_magic_link_email(%Config{} = conf, user, link) do
    conf.mail_builder.create_magic_link_email(user, link)
  end
end
