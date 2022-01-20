defmodule Yemma.Config do
  @type t :: %__MODULE__{
          routes: module()
        }

  @enforce_keys [:routes]
  defstruct routes: nil

  @spec new(Keyword.t()) :: t()
  def new(opts) when is_list(opts) do
    struct!(__MODULE__, opts)
  end
end
