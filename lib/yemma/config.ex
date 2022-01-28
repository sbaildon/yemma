defmodule Yemma.Config do
  @type t :: %__MODULE__{
          routes: module(),
          signed_in_dest: {module(), function(), list()} | binary(),
          cookie_domain: String.t(),
          pubsub_server: module(),
          secret_key_base: String.t(),
          repo: nil,
          name: term(),
          notifier: module(),
          mail_builder: module(),
          user: module(),
          token: module(),
          endpoint: module()
        }

  @enforce_keys [:routes, :secret_key_base, :repo]
  defstruct routes: nil,
            signed_in_dest: "/",
            cookie_domain: nil,
            pubsub_server: nil,
            secret_key_base: nil,
            repo: nil,
            name: Yemma,
            notifier: {Yemma.Notifiers.NaiveMailer, mailer: Yemma.Mailer},
            mail_builder: Yemma.Mail.UnbrandedBuilder,
            user: nil,
            token: nil,
            endpoint: nil

  @spec new(Keyword.t()) :: t()
  def new(opts) when is_list(opts) do
    Enum.each(opts, &validate_opt!/1)
    struct!(__MODULE__, opts)
  end

  defp validate_opt!({:routes, routes}),
    do: validate_opt!(:atom, routes, ":repo must be an atom, eg. MyAppWeb.Routes.Helpers")

  defp validate_opt!({:signed_in_dest, {m, f, a}}) when is_list(a) do
    arity = length(a)

    unless function_exported?(m, f, arity),
      do: raise(ArgumentError, ":signed_in_dest, #{m} does not export #{f}/#{arity}")
  end

  defp validate_opt!({:signed_in_dest, dest}),
    do: validate_opt!(:binary, dest, ":signed_in_dest must be either an mfa tuple or string")

  defp validate_opt!({:cookie_domain, cookie_domain}),
    do: validate_opt!(:binary, cookie_domain, ":cookie_domain must be a string")

  defp validate_opt!({:pubsub_server, pubsub_server}),
    do: validate_opt!(:atom, pubsub_server, ":pubsub_server must be an atom, eg. MyApp.PubSub")

  defp validate_opt!({:secret_key_base, secret_key_base}),
    do: validate_opt!(:binary, secret_key_base, ":secret_key_base must be a string")

  defp validate_opt!({:repo, repo}),
    do: validate_opt!(:atom, repo, ":repo must be an atom, eg. MyApp.Repo")

  defp validate_opt!({:name, _}), do: :ok

  defp validate_opt!({:notifier, {notifier, opts}}) do
    validate_opt!(
      :atom,
      notifier,
      ":notifier must be an atom or {atom, list} tuple, eg. Yemma.Notifiers.NaiveMailer"
    )

    validate_opt!(:list, opts, ":notifier opts must be a list")
  end

  defp validate_opt!({:notifier, notifier}) do
    validate_opt!(
      :atom,
      notifier,
      ":notifier must be an atom or {atom, list} tuple, eg. Yemma.Notifiers.NaiveMailer"
    )
  end

  defp validate_opt!({:mail_builder, mail_builder}) do
    validate_opt!(
      :atom,
      mail_builder,
      ":mail_builder must be an atom, eg. Yemma.Mail.UnbrandedBuilder"
    )
  end

  defp validate_opt!({:user, user}) do
    validate_opt!(:atom, user, ":user must be an atom, eg. Yemma.Users.User")
  end

  defp validate_opt!({:token, token}) do
    validate_opt!(:atom, token, ":token must be an atom, eg. Yemma.Users.UserToken")
  end

  defp validate_opt!({:endpoint, endpoint}) do
    validate_opt!(:atom, endpoint, ":endpoint must be an atom, eg. MyAppWeb.Endpoint")
  end

  defp validate_opt!(:binary, opt, message) do
    unless is_binary(opt) do
      raise(ArgumentError, message)
    end
  end

  defp validate_opt!(:atom, opt, message) do
    unless is_atom(opt) do
      raise(ArgumentError, message)
    end
  end

  defp validate_opt!(:list, opt, message) do
    unless is_list(opt) do
      raise(ArgumentError, message)
    end
  end
end
