defmodule Github.Repo do
  @moduledoc """
  Context responsible of dealing with Github PRs state
  """

  defstruct repo_state: MapSet.new(),
            owner: "",
            repo: "",
            notify: nil,
            api_token: nil,
            changes: MapSet.new(),
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

  def changes(%Github.Repo{repo_state: before}, %Github.Repo{repo_state: now}) do
    MapSet.difference(now, before)
  end

  def update_state(state, new_state) do
    diff = changes(state, new_state)
    intersection = MapSet.intersection(state.repo_state, new_state.repo_state)
    new_repo_state = MapSet.union(intersection, diff)
    {diff, %{state | repo_state: new_repo_state}}
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
    data
    |> Enum.map(&%{number: Map.get(&1, "number"), hash: Map.get(&1, "headRefOid")})
    |> MapSet.new()
  end
end
