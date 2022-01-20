defmodule YemmaWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, views, channels and so on.

  This can be used in your application as:

      use YemmaWeb, :controller
      use YemmaWeb, :view

  The definitions below will be executed for every view,
  controller, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define any helper function in modules
  and import those modules here.
  """

  def controller do
    quote do
      use Phoenix.Controller, namespace: YemmaWeb

      import Plug.Conn
      import YemmaWeb.Gettext
      unquote(route_helper())
    end
  end

  def view do
    quote do
      use Phoenix.View,
        root: "lib/yemma_web/templates",
        namespace: YemmaWeb

      # Import convenience functions from controllers
      import Phoenix.Controller,
        only: [get_flash: 1, get_flash: 2, view_module: 1, view_template: 1]

      unquote(route_helper())

      # Include shared imports and aliases for views
      unquote(view_helpers())
    end
  end

  def component do
    quote do
      use Phoenix.Component

      unquote(view_helpers())
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
      import YemmaWeb.Gettext
    end
  end

  defp view_helpers do
    quote do
      # Use all HTML functionality (forms, tags, etc)
      use Phoenix.HTML

      import Phoenix.LiveView.Helpers, only: [form: 1]

      # Import basic rendering functionality (render, render_layout, etc)
      import Phoenix.View

      import YemmaWeb.ErrorHelpers
      import YemmaWeb.Gettext
      unquote(route_helper())
    end
  end

  def route_helper do
    quote do
      def routes() do
        Yemma.config()
        |> Map.fetch!(:routes)
      end
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
