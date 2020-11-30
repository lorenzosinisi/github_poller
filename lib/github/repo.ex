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
  def new, do: %Github.Repo{notify: self()}

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

  defp changes(%Github.Repo{repo_state: previous_prs}, %Github.Repo{repo_state: new_prs}) do
    Enum.reduce(new_prs, {Map.new(), previous_prs}, fn {number, pr}, {diff, prs} ->
      previous_hash = get_in(prs, [number, :hash])
      new_hash = get_in(pr, [:hash])

      cond do
        # the PR is new, the PRs in the state are empty
        previous_hash == nil && map_size(prs) == 0 ->
          {diff, Map.put(prs, number, pr)}

        # we already know about some PRs, but this is a new one
        previous_hash == nil ->
          {Map.put(diff, number, pr), Map.put(prs, number, pr)}

        # there is no hash, what?
        new_hash == nil ->
          raise("the key hash must be present")

        # no change detected
        previous_hash == new_hash ->
          # we refresh the PR struct anyway
          {diff, Map.put(prs, number, pr)}

        # change detected! The hash has changed, which means that the code has changed
        previous_hash !== new_hash ->
          # report this as change and refresh the state as well
          {Map.put(diff, number, pr), Map.put(prs, number, pr)}
      end
    end)
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
