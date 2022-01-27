defmodule YemmaWeb do
  def controller do
    quote do
      use Phoenix.Controller, namespace: YemmaWeb

      import Plug.Conn
      import YemmaWeb.Gettext

      def action(%{assigns: assigns} = conn, _opts) do
        {view, assigns} = Map.pop(assigns, :view, nil)

        conn = if view, do: put_view(conn, view), else: conn
        conn = %{conn | assigns: assigns}

        yemma_conf = %{
          name: conn.private.yemma_name,
          routes: conn.private.yemma_routes
        }

        args = [conn, conn.params, yemma_conf]
        apply(__MODULE__, action_name(conn), args)
      end
    end
  end

  def view do
    quote do
      use Phoenix.View,
        root: "lib/yemma_web/templates",
        namespace: YemmaWeb

      import Phoenix.Controller,
        only: [get_flash: 1, get_flash: 2, view_module: 1, view_template: 1]

      unquote(view_helpers())
    end
  end

  defp view_helpers do
    quote do
      use Phoenix.HTML

      import Phoenix.LiveView.Helpers, only: [form: 1]

      import Phoenix.View

      import YemmaWeb.ErrorHelpers
      import YemmaWeb.Gettext
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
