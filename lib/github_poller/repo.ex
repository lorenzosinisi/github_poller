defmodule Github.Repo do
  @moduledoc """
  Context responsible of dealing with Github PRs state
  """

  defstruct repo_state: Map.new(),
            owner: "",
            repo: "",
            notify: nil,
            api_token: nil,
            changes: Map.new(),
            every: :timer.seconds(5)

  @type t :: %__MODULE__{}

  defimpl Collectable do
    def into(original) do
      collector_fun = fn
        struct, {:cont, {key, val}} -> struct!(struct, [{key, val}])
        struct, :done -> struct
        _struct, :halt -> :ok
      end

      {original, collector_fun}
    end
  end

  @spec new() :: Github.Repo.t()
  def new(), do: %Github.Repo{notify: self()}

  def changes(%Github.Repo{repo_state: previous_prs}, %Github.Repo{repo_state: new_prs}) do
    Enum.reduce(new_prs, {Map.new(), previous_prs}, fn {number, pr}, {diff, prs} ->
      previous_hash = get_in(prs, [number, :hash])
      new_hash = get_in(pr, [:hash])

      if previous_hash === new_hash do
        {diff, prs}
      else
        {Map.put(diff, number, pr), Map.put(prs, number, pr)}
      end
    end)
  end

  def update_state(state, new_state) do
    {diff, new_state} = changes(state, new_state)
    {diff, %{state | repo_state: new_state}}
  end

  def fetch_repo_state!(%{api_token: token, owner: owner, repo: repository}) do
    token
    |> Github.Client.latest_prs(owner, repository)
    |> case do
      {:ok, data} ->
        {:ok, %Github.Repo{repo_state: normalize(data)}}

      error ->
        error
    end
  end

  defp normalize(data) do
    Enum.map(
      data,
      &{
        Map.get(&1, "number"),
        %{
          number: Map.get(&1, "number"),
          title: Map.get(&1, "title"),
          hash: Map.get(&1, "headRefOid")
        }
      }
    )
    |> Enum.into(%{})
  end
end
