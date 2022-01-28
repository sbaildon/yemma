defmodule Yemma.Notifier do
  alias Yemma.Config

  @type user :: map()
  @type link :: String.t()

  @callback deliver_magic_link_instructions(user(), link(), Keyword.t()) ::
              {:ok, any()} | {:error, any()}

  @callback deliver_update_email_instructions(user(), link(), Keyword.t()) ::
              {:ok, any()} | {:error, any()}

  def deliver_magic_link_instructions(%Config{} = conf, user, link) do
    {notifier, opts} = notifier_and_opts(conf.notifier)
    notifier.deliver_magic_link_instructions(user, link, opts)
  end

  def deliver_update_email_instructions(%Config{} = conf, user, link) do
    {notifier, opts} = notifier_and_opts(conf.notifier)
    notifier.deliver_update_email_instructions(user, link, opts)
  end

  defp notifier_and_opts(notifier) when is_atom(notifier),
    do: {notifier, []}

  defp notifier_and_opts({notifier, opts}) when is_atom(notifier) and is_list(opts),
    do: {notifier, opts}
end
