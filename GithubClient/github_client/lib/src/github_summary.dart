import 'package:flutter/material.dart';
import 'package:fluttericon/octicons_icons.dart';
import 'package:github/github.dart';
import 'package:url_launcher/url_launcher.dart';

class GithubSummary extends StatefulWidget {
  const GithubSummary({required this.github, Key? key}) : super(key: key);
  final GitHub github;

  @override
  _GithubSummaryState createState() => _GithubSummaryState();
}

class _GithubSummaryState extends State<GithubSummary> {
  int _selectedInd = 0;

  @override
  Widget build(BuildContext ctx) {
    return Row(
      children: [
        NavigationRail(
          onDestinationSelected: (index) => setState(() {
            _selectedInd = index;
          }),
          selectedIndex: _selectedInd,
          labelType: NavigationRailLabelType.selected,
          destinations: const [
            NavigationRailDestination(
                icon: Icon(Octicons.repo), label: Text("Repositories")),
            NavigationRailDestination(
                icon: Icon(Octicons.issue_opened),
                label: Text("Assigned Issues")),
            NavigationRailDestination(
                icon: Icon(Octicons.git_pull_request),
                label: Text("Pull Requests")),
          ],
        ),
        const VerticalDivider(thickness: 1, width: 1),
        Expanded(
          child: IndexedStack(
            index: _selectedInd,
            children: [
              RepositoriesList(github: widget.github),
              AssignedIssuesList(github: widget.github),
              PullRequestsList(github: widget.github)
            ],
          ),
        )
      ],
    );
  }
}

class RepositoriesList extends StatefulWidget {
  const RepositoriesList({required this.github, Key? key}) : super(key: key);
  final GitHub github;

  @override
  _RepositriesListState createState() => _RepositriesListState();
}

class _RepositriesListState extends State<RepositoriesList> {
  @override
  initState() {
    super.initState();
    _repos = widget.github.repositories.listRepositories().toList();
  }

  late Future<List<Repository>> _repos;

  @override
  Widget build(BuildContext ctx) {
    return FutureBuilder<List<Repository>>(
      future: _repos,
      builder: (ctx, snap) {
        if (snap.hasError) {
          return Center(child: Text("${snap.error}"));
        }

        if (!snap.hasError) {
          return const Center(child: CircularProgressIndicator());
        }

        var repos = snap.data;

        return ListView.builder(itemBuilder: (ctx, index) {
          var repo = repos![index];
          return ListTile(
              title: Text("${repo.owner?.login ?? ''}/${repo.name}"),
              subtitle: Text(repo.description),
              onTap: () => _launchUrl(ctx, repo.htmlUrl));
        });
      },
    );
  }
}

class AssignedIssuesList extends StatefulWidget {
  const AssignedIssuesList({required this.github, Key? key}) : super(key: key);
  final GitHub github;

  @override
  _AssignedIssuesListState createState() => _AssignedIssuesListState();
}

class _AssignedIssuesListState extends State<AssignedIssuesList> {
  @override
  void initState() {
    super.initState();
    _assignedIssues = widget.github.issues.listByUser().toList();
  }

  late Future<List<Issue>> _assignedIssues;

  @override
  Widget build(BuildContext ctx) {
    return FutureBuilder<List<Issue>>(
      future: _assignedIssues,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        var assignedIssues = snapshot.data;
        return ListView.builder(
          itemBuilder: (context, index) {
            var assignedIssue = assignedIssues![index];
            return ListTile(
              title: Text(assignedIssue.title),
              subtitle: Text('${_nameWithOwner(assignedIssue)} '
                  'Issue #${assignedIssue.number} '
                  'opened by ${assignedIssue.user?.login ?? ''}'),
              onTap: () => _launchUrl(context, assignedIssue.htmlUrl),
            );
          },
          itemCount: assignedIssues!.length,
        );
      },
    );
  }

  String _nameWithOwner(Issue assignedIssue) {
    final endIndex = assignedIssue.url.lastIndexOf('/issues/');
    return assignedIssue.url.substring(29, endIndex);
  }
}

class PullRequestsList extends StatefulWidget {
  const PullRequestsList({required this.github, Key? key}) : super(key: key);
  final GitHub github;

  @override
  _PullRequestsListState createState() => _PullRequestsListState();
}

class _PullRequestsListState extends State<PullRequestsList> {
  @override
  initState() {
    super.initState();
    _pullRequests = widget.github.pullRequests
        .list(RepositorySlug('flutter', 'flutter'))
        .toList();
  }

  late Future<List<PullRequest>> _pullRequests;

  @override
  Widget build(BuildContext ctx) {
    return FutureBuilder<List<PullRequest>>(
      future: _pullRequests,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        var pullRequests = snapshot.data;
        return ListView.builder(
          itemBuilder: (context, index) {
            var pullRequest = pullRequests![index];
            return ListTile(
              title: Text(pullRequest.title ?? ''),
              subtitle: Text('flutter/flutter '
                  'PR #${pullRequest.number} '
                  'opened by ${pullRequest.user?.login ?? ''} '
                  '(${pullRequest.state?.toLowerCase() ?? ''})'),
              onTap: () => _launchUrl(context, pullRequest.htmlUrl ?? ''),
            );
          },
          itemCount: pullRequests!.length,
        );
      },
    );
  }
}

Future<void> _launchUrl(BuildContext ctx, String url) async {
  if (await canLaunch(url)) {
    await launch(url);
  } else {
    return showDialog(
        context: ctx,
        builder: (ctx) => AlertDialog(
                title: const Text("Navigation Error"),
                content: Text("Could not launch $url"),
                actions: <Widget>[
                  TextButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                      },
                      child: const Text("close"))
                ]));
  }
}
