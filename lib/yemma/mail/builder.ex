defmodule Yemma.Mail.Builder do
  @type user :: map()
  @type link :: String.t()

  @callback create_magic_link_email(user(), link()) :: Swoosh.Email.t()
  @callback create_update_email_instructions(user(), link()) :: Swoosh.Email.t()

  def create_magic_link_email(builder, user, link) do
    builder.create_magic_link_email(user, link)
  end

  def create_update_email_instructions(builder, user, link) do
    builder.create_update_email_instructions(user, link)
  end
end
