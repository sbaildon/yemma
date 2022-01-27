defmodule Yemma.Mail.Dispatcher do
  alias Yemma.Config

  @type conf :: Config.t()
  @type user :: map()
  @type link :: String.t()

  @callback deliver_magic_link_instructions(conf(), user(), link(), Keyword.t()) ::
              {:ok, any()} | {:error, any()}

  @callback deliver_update_email_instructions(conf(), user(), link(), Keyword.t()) ::
              {:ok, any()} | {:error, any()}

  def deliver_magic_link_instructions(%Config{} = conf, user, link) do
    {dispatcher, opts} = dispatcher_and_opts(conf.mail_dispatcher)
    dispatcher.deliver_magic_link_instructions(conf, user, link, opts)
  end

  def deliver_update_email_instructions(%Config{} = conf, user, link) do
    {dispatcher, opts} = dispatcher_and_opts(conf.mail_dispatcher)
    dispatcher.deliver_update_email_instructions(conf, user, link, opts)
  end

  defp dispatcher_and_opts(dispatcher) when is_atom(dispatcher),
    do: {dispatcher, []}

  defp dispatcher_and_opts({dispatcher, opts}),
    do: {dispatcher, opts}
end
