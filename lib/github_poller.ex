defmodule GithubPoller do
  use Parent.GenServer
  alias GithubPoller.PullRequest

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
    state = Enum.into(opts, PullRequest.new()) |> IO.inspect(label: :state)

    # starts the periodic poller
    start_poller(state)

    {:ok, state}
  end

  @impl GenServer
  def handle_info({:new_repo_state, new_repo_state}, %{initialized: true} = state) do
    changes = PullRequest.changes(state, new_repo_state)

    if Enum.any?(changes) do
      send(
        state.notify,
        IO.inspect({:repo_update, %{owner: state.owner, repo: state.repo, changes: changes}})
      )
    end

    {:noreply, PullRequest.update_state(state, new_repo_state)}
  end

  @impl GenServer
  def handle_info({:new_repo_state, new_repo_state}, state) do
    {:noreply, PullRequest.update_state(state, new_repo_state)}
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
    {:ok, new_state} = PullRequest.fetch_repo_state!(github_opts)
    send(parent, {:new_repo_state, new_state})
  end
end
