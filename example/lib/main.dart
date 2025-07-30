import 'dart:io' show File, Platform;

import 'package:desktop_webview_linux/desktop_webview_linux.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<void> _openWebView() async {
    if (!Platform.isLinux) {
      return;
    }

    const htmlContent = '''
      <!DOCTYPE html>
      <html>
        <head><title>Demo</title></head>
        <body>
          <h2>Click to send message to Dart</h2>
          <button onclick="window.webkit.messageHandlers.onTokenReceived.postMessage('test-token')">
            Send Token
          </button>
        </body>
      </html>
    ''';

    const jsCode = '''
      console.log('JS code injected');
    ''';

    var handled = false;

    try {
      final tempDir = await getTemporaryDirectory();
      final htmlFile = File(p.join(tempDir.path, 'webview_test.html'));
      await htmlFile.writeAsString(htmlContent);

      final documentDir = await getApplicationDocumentsDirectory();
      final webviewPath = p.join(documentDir.path, 'desktop_webview_window');

      final config = CreateConfiguration(
        title: 'WebView Example',
        windowWidth: 500,
        windowHeight: 400,
        userDataFolderWindows: webviewPath,
      );

      final webview = await WebviewWindow.create(configuration: config);
      debugPrint('✅ WebView created, launching...');

      webview
        ..registerJavaScriptMessageHandler('onTokenReceived', (name, body) {
          if (handled) {
            return;
          }
          handled = true;
          debugPrint('✅ JS Message received: $body');
          Future.delayed(const Duration(milliseconds: 300), webview.close);
        })
        ..registerJavaScriptMessageHandler('onError', (name, body) {
          if (handled) {
            return;
          }
          handled = true;
          debugPrint('❌ JS Error: $body');
          Future.delayed(const Duration(milliseconds: 300), webview.close);
        })
        ..launch(htmlFile.uri.toString());

      await Future<void>.delayed(const Duration(milliseconds: 1200));
      await webview.evaluateJavaScript(jsCode);
    } on Object catch (e, stack) {
      debugPrint('❌ Exception in WebView: $e\n$stack');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Linux WebView (inline)')),
        body: Center(
          child: ElevatedButton(
            onPressed: _openWebView,
            child: const Text('Open WebView'),
          ),
        ),
      ),
    );
  }
}
