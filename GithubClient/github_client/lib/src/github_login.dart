import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:oauth2/oauth2.dart' as oauth2;
import 'package:url_launcher/url_launcher.dart';

final _authEndpoint = Uri.parse('https://github.com/login/oauth/authorize');
final _tokenEndpoint = Uri.parse('https://github.com/login/oauth/access_token');

class GithubLoginWidget extends StatefulWidget {

  const GithubLoginWidget({
    required this.builder,
    required this.githubClientId,
    required this.githubClientSecret,
    required this.githubScopes,
    Key? key
  }) : super(key: key);

  final AuthenticatedBuilder builder;
  final String githubClientId;
  final String githubClientSecret;
  final List<String> githubScopes;

  @override
  _GithubLoginState createState() => _GithubLoginState();

}

typedef AuthenticatedBuilder = Widget Function (
  BuildContext ctx, oauth2.Client client);

class _GithubLoginState extends State<GithubLoginWidget> {

  HttpServer? _redirServer;
  oauth2.Client? _client;

  @override
  Widget build(BuildContext ctx) {
    final client = _client;

    if (client != null) {
      return widget.builder(ctx, client);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Github Login')
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            await _redirServer?.close();
            _redirServer = await HttpServer.bind('localhost', 0);
            var authenticatedHttpClient = await _getOauth2Client(
              Uri.parse('http://localhost:${_redirServer!.port}/auth')
            );
            setState(() {
              _client = authenticatedHttpClient;
            });
          },
          child: const Text('Login to Github')
        ),
      ),
    );
  }

  Future<oauth2.Client> _getOauth2Client(Uri redirUrl) async {
    if (widget.githubClientId.isEmpty || widget.githubClientSecret.isEmpty) {
      throw const GithubLoginException('githubClientId and githubClientSecret must be not empty. '
          'See `lib/github_oauth_credentials.dart` for more detail.');
    }

    var grant = oauth2.AuthorizationCodeGrant(
      widget.githubClientId,
      _authEndpoint,
      _tokenEndpoint,
      secret: widget.githubClientSecret,
      httpClient: _JsonAcceptingHttpClient()
    );
    var authUrl = grant.getAuthorizationUrl(redirUrl, scopes: widget.githubScopes);

    await _redirect(authUrl);
    var responseQueryParams = await _listen();
    var client = await grant.handleAuthorizationResponse(responseQueryParams);
    
    return client;
  }

  Future<void> _redirect(Uri authUrl) async {
    var url = authUrl.toString();
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw GithubLoginException('Could not launch $url');
    }
  }

  Future<Map<String,String>> _listen() async {
    var request = await _redirServer!.first;
    var params = request.uri.queryParameters;

    request.response.statusCode = 200;
    request.response.headers.set('content-type', 'text/plain');
    request.response.writeln('Authenticated! You can close this tab');
    await request.response.close();
    await _redirServer!.close();
    _redirServer = null;
    return params;
  }
}

class _JsonAcceptingHttpClient extends http.BaseClient {
  final _httpClient = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['Accept'] = 'application/json';
    return _httpClient.send(request);
  }
}

class GithubLoginException implements Exception {
  const GithubLoginException(this.message);

  final String message;
  @override
  String toString() => message;
}
