# GithubPoller

**WIP implementation of Github Client Poller**

## Client Usage

```elixir
token = "your github token here"
github_org_name = "lorenzosinisi"
github_repo_name = "retex"
GithubPoller.Client.latest_prs(token, github_org_name, github_repo_name)
```

