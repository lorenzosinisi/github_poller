# GithubPoller

**WIP implementation of Github Client Poller**

## Client Usage

```elixir
token = "your github token here"
github_org_name = "lorenzosinisi"
github_repo_name = "retex"
GithubPoller.Client.latest_prs(token, github_org_name, github_repo_name)
{:ok,
 %{
   "data" => %{
     "repository" => %{
       "pullRequests" => %{
         "nodes" => [
           %{
             "baseRefName" => "master",
             "headRefName" => "feature/rule_engine",
             "headRefOid" => "6330d7a229f61d9c47da643d67f1ffddbc0691b7",
             "mergeable" => "UNKNOWN",
             "number" => 11,
             "potentialMergeCommit" => nil,
             "reviews" => %{"nodes" => []},
             "title" => "Feature/rule engine"
           },
           %{
             "baseRefName" => "master",
             "headRefName" => "generic-attributes",
             "headRefOid" => "d52a426d99b72ba222be93dfa9ab948963516fa0",
             "mergeable" => "UNKNOWN",
             "number" => 10,
             "potentialMergeCommit" => nil,
             "reviews" => %{"nodes" => []},
             "title" => "Generic attributes"
           },
           %{
             "baseRefName" => "master",
             "headRefName" => "bug/negated-attributes-should-act-as-filters",
             "headRefOid" => "bb1646ecf0d1280f759a350b600a04f0c64ac901",
             "mergeable" => "UNKNOWN",
             "number" => 9,
             "potentialMergeCommit" => nil,
             "reviews" => %{"nodes" => []},
             "title" => "BUG - Reproduce the issue"
           },
           ...
         ]
       }
     }
   }
 }}
```

