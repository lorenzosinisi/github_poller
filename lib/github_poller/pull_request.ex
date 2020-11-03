defmodule GithubPoller.PullRequest do
  @moduledoc """
  Context responsible of dealing with Github PRs state
  """
  alias __MODULE__

  defmodule State do
    @moduledoc """
    The state of pull requests, it works as a container
    for and it is used to manipulate pull requests data
    """
    defstruct initialized: false, repo_state: MapSet.new(), owner: "", repo: "", notify: nil

    defimpl Collectable do
      def into(original) do
        collector_fun = fn
          struct, {:cont, {key, val}} -> Map.put(struct, key, val)
          struct, :done -> struct
          _struct, :halt -> :ok
        end

        {original, collector_fun}
      end
    end
  end

  @spec new() :: GithubPoller.PullRequest.State.t()
  def new(), do: %PullRequest.State{}

  def changes(%PullRequest.State{repo_state: before}, %PullRequest.State{repo_state: now}) do
    MapSet.difference(now, before)
  end

  def update_state(state, new_state) do
    diff = changes(state, new_state)
    intersection = MapSet.intersection(state.repo_state, new_state.repo_state)
    new_repo_state = MapSet.union(intersection, diff)
    %{state | repo_state: new_repo_state, initialized: true}
  end

  def fetch_repo_state!(%{api_token: token, owner: owner, repo: repository}) do
    token
    |> GithubPoller.Client.latest_prs(owner, repository)
    |> GithubPoller.Client.request()
    |> case do
      {:ok, data} ->
        {:ok, %PullRequest.State{repo_state: normalize(data)}}

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
