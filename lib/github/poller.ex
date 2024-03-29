defmodule Github.Poller do
  @moduledoc """
   Expected usage:

    GithubPoller.start_link(api_token: "foo", owner: "bar", repo: "baz", notify: self())

   or as a child of a supervisor/parent:

    {Github.Poller, api_token: "foo", ...}

   This will start the poller which will send updates (e.g. PR changed) to the `:notify` process.
  """
  use Parent.GenServer
  alias Github.Repo
  require Logger

  def start_link(opts) do
    {gen_server_opts, opts} = Keyword.split(opts, [:name])
    Parent.GenServer.start_link(__MODULE__, opts, gen_server_opts)
  end

  @impl GenServer
  def init(opts) do
    # repo_state will contain the known state of the given repo, such as open pull request with
    # the last fetched data
    state = Enum.into(opts, Repo.new())

    # starts the periodic poller
    start_poller(state)

    {:ok, state}
  end

  @impl GenServer
  def handle_info({:new_repo_state, new_repo_state}, state) do
    {changes, new_state} = Repo.update_state(state, new_repo_state)
    if Enum.any?(changes), do: notify_subscriber(changes, new_state)
    {:noreply, new_state}
  end

  @impl GenServer
  def handle_info({:repo_update, _repo_state} = message, state) do
    Logger.debug("#{__MODULE__} received #{inspect(message)}")
    {:noreply, state}
  end

  defp notify_subscriber(changes, %{repo_state: _} = state) do
    send(
      state.notify,
      {:repo_update, %{owner: state.owner, repo: state.repo, changes: changes}}
    )
  end

  defp start_poller(state) do
    # This will start the periodic poller as a child of this `Parent.GenServer`. The poller will
    # ask github for new data every `x` and send the message to this process.

    parent = self()
    github_opts = Map.take(state, [:api_token, :owner, :repo])
    every = Map.get(state, :every)

    Parent.start_child(
      {Periodic,
       every: every,
       run: fn -> poll(parent, github_opts) end,
       initial_delay: 0,
       on_overlap: :stop_previous}
    )
  end

  defp poll(parent, github_opts) do
    {:ok, new_state} = Repo.fetch_repo_state!(github_opts)
    send(parent, {:new_repo_state, new_state})
  end
end
