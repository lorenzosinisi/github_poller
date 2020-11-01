defmodule GithubPoller do
  use Parent.GenServer

  # Expected usage:
  #
  #   GithubPoller.start_link(api_token: "foo", owner: "bar", repo: "baz", notify: self())
  #
  # or as a child of a supervisor/parent:
  #
  #  {Github.Poller, api_token: "foo", ...}
  #
  # This will start the poller which will send updates (e.g. PR changed) to the `:notify` process.
  def start_link(opts) do
    {gen_server_opts, opts} = Keyword.split(opts, [:name])
    Parent.GenServer.start_link(__MODULE__, opts, gen_server_opts)
  end

  @impl GenServer
  def init(opts) do
    # repo_state will contain the known state of the given repo, such as open pull request with
    # the last fetched data
    state = Enum.into(opts, %{repo_state: MapSet.new([])})

    # starts the periodic poller
    start_poller(state)

    {:ok, state}
  end

  @impl GenServer
  def handle_info({:github_data, new_repo_state}, state) do
    # This is invoked when poll result arrived. At this point, we need to do the following:
    #
    #   1. Figure out the diff between the new state and the one we have in `state.new_repo_state`

    difference = MapSet.difference(state.repo_state, new_repo_state)

    #   2. Send a single message to the client process containing all updated pull requests
    send(
      state.notify,
      IO.inspect({:repo_update, %{owner: state.owner, repo: state.repo, changes: difference}},
        label: :something_changed
      )
    )

    #   3. Update the state to contain the new repo state
    repo_state =
      state
      |> Map.get(:repo_state)
      |> MapSet.intersection(new_repo_state)
      |> MapSet.union(difference)

    {:noreply, %{state | repo_state: repo_state}}
  end

  defp start_poller(state) do
    # This will start the periodic poller as a child of this `Parent.GenServer`. The poller will
    # ask github for new data every `x` and send the message to this process.

    parent = self()
    github_opts = Map.take(state, [:api_token, :owner, :repo])

    Parent.start_child({
      Periodic,
      # We could fetch the poll interval from user provided opts
      every: :timer.seconds(5),
      run: fn -> poll(parent, github_opts) end,
      initial_delay: 0,
      on_overlap: :stop_previous
    })
  end

  defp poll(parent, github_opts) do
    IO.puts("polling github")
    data = fetch_repo_state!(github_opts)
    send(parent, {:github_data, data})
  end

  defp fetch_repo_state!(%{api_token: token, owner: owner, repo: repository}) do
    token
    |> GithubPoller.Client.latest_prs(owner, repository)
    |> GithubPoller.Client.request()
    |> case do
      {:ok, data} ->
        data
        |> Enum.map(fn pr -> {Map.get(pr, "number"), Map.get(pr, "headRefOid")} end)
        |> Enum.into(%{})
        |> MapSet.new()

      error ->
        raise(error)
    end
  end
end
