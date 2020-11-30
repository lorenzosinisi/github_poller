# GithubPoller

**Receive a message every time a PR is updated, checking them at constant intervals**

The poller will periodically check the PRs on your Github repository and send a message
to the GenServer which has spawned the process if any PR has changed.


## Client Usage:

```elixir
token = "your github token here"
github_org_name = "lorenzosinisi"
github_repo_name = "github_poller"
notify = self() # the GenServer will receive info messages when some PR is updated, default to self()
Github.Poller.start_link(api_token: token, owner: github_org_name, repo: github_repo_name, every: :timer.seconds(1), notify: notify)
```

## Implement your own GenServer that will be notified of PR changes:

```elixir
defmodule Example do
  use GenServer
  ...
  # add this
  @impl GenServer
  def handle_info({:repo_update, _repo_state} = message, state) do
    Logger.debug("#{__MODULE__} received #{inspect(message)}")
    {:noreply, state}
  end
end
```


