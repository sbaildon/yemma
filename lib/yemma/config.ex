defmodule Yemma.Config do
  @type t :: %__MODULE__{
          routes: module(),
          signed_in_dest: {module(), function(), list()} | binary(),
          cookie_domain: String.t(),
          pubsub_server: module()
        }

  @enforce_keys [:routes]
  defstruct routes: nil,
            signed_in_dest: "/",
            cookie_domain: nil,
            pubsub_server: nil

  @spec new(Keyword.t()) :: t()
  def new(opts) when is_list(opts) do
    Enum.each(opts, &validate_opt!/1)
    struct!(__MODULE__, opts)
  end

  defp validate_opt!({:routes, routes}) do
    required_functions = [user_session_url: 2, user_settings_url: 2, user_confirmation_url: 3]

    unexported =
      Enum.reject(required_functions, fn {func, arity} ->
        function_exported?(routes, func, arity)
      end)

    if length(unexported) > 0 do
      raise ArgumentError, ":routes, #{routes} needs to export: #{Enum.join(unexported, ", ")}"
    end
  end

  defp validate_opt!({:signed_in_dest, {m, f, a}}) when is_list(a) do
    arity = length(a)

    unless function_exported?(m, f, arity),
      do: raise(ArgumentError, ":signed_in_dest, #{m} does not export #{f}/#{arity}")
  end

  defp validate_opt!({:signed_in_dest, dest}),
    do: validate_opt!(:binary, dest, ":signed_in_dest must be either an mfa tuple or string")

  defp validate_opt!({:cookie_domain, cookie_domain}),
    do: validate_opt!(:binary, cookie_domain, ":cookie_domain must be a string")

  defp validate_opt!({:pubsub_server, pubsub_server}) do
    validate_opt!(:atom, pubsub_server, ":pubsub_server must be an atom, eg. MyApp.PubSub")
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
end
