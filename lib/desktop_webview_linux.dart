import 'dart:async';
import 'dart:io';

import 'package:desktop_webview_linux/src/create_configuration.dart';
import 'package:desktop_webview_linux/src/message_channel.dart';
import 'package:desktop_webview_linux/src/webview.dart';
import 'package:desktop_webview_linux/src/webview_impl.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

export 'src/create_configuration.dart';
export 'src/title_bar.dart';
export 'src/webview.dart';

final List<WebviewImpl> _webviews = [];

class WebviewWindow {
  static const MethodChannel _channel = MethodChannel('desktop_webview_linux');

  static const _otherIsolateMessageHandler = ClientMessageChannel();

  static bool _inited = false;

  static void _init() {
    if (_inited) {
      return;
    }
    _inited = true;
    _channel.setMethodCallHandler((call) async {
      try {
        return await _handleMethodCall(call);
      } on Object catch (e, s) {
        debugPrint('method: ${call.method} args: ${call.arguments}');
        debugPrint('handleMethodCall error: $e $s');
      }
    });
    _otherIsolateMessageHandler.setMessageHandler((call) async {
      try {
        return await _handleOtherIsolateMethodCall(call);
      } on Object catch (e, s) {
        debugPrint('_handleOtherIsolateMethodCall error: $e $s');
      }
    });
  }

  /// Check if WebView runtime is available on the current devices.
  static Future<bool> isWebviewAvailable() async {
    if (Platform.isWindows) {
      final ret = await _channel.invokeMethod<bool>('isWebviewAvailable');
      return ret ?? false;
    }
    return true;
  }

  static Future<Webview> create({CreateConfiguration? configuration}) async {
    configuration ??= CreateConfiguration.platform();
    _init();
    final viewId =
        await _channel.invokeMethod('create', configuration.toMap()) as int;
    final webview = WebviewImpl(viewId, _channel);
    _webviews.add(webview);
    return webview;
  }

  static Future<dynamic> _handleOtherIsolateMethodCall(MethodCall call) async {
    final webViewId = call.arguments['webViewId'] as int;
    final webView = _webviews.cast<WebviewImpl?>().firstWhere(
      (w) => w?.viewId == webViewId,
      orElse: () => null,
    );
    if (webView == null) {
      return;
    }
    switch (call.method) {
      case 'onBackPressed':
        await webView.back();
      case 'onForwardPressed':
        await webView.forward();
      case 'onRefreshPressed':
        await webView.reload();
      case 'onStopPressed':
        await webView.stop();
      case 'onClosePressed':
        webView.close();
    }
  }

  static Future<dynamic> _handleMethodCall(MethodCall call) async {
    final args = call.arguments as Map;
    final viewId = args['id'] as int;
    final webview = _webviews.cast<WebviewImpl?>().firstWhere(
      (e) => e?.viewId == viewId,
      orElse: () => null,
    );
    assert(webview != null);
    if (webview == null) {
      return;
    }
    switch (call.method) {
      case 'onWindowClose':
        _webviews.remove(webview);
        webview.onClosed();
      case 'onJavaScriptMessage':
        webview.onJavaScriptMessage(args['name'] as String, args['body']);
      case 'runJavaScriptTextInputPanelWithPrompt':
        return webview.onRunJavaScriptTextInputPanelWithPrompt(
          args['prompt'] as String,
          args['defaultText'] as String,
        );
      case 'onHistoryChanged':
        webview.onHistoryChanged(
          args['canGoBack'] as bool,
          args['canGoForward'] as bool,
        );
        await _otherIsolateMessageHandler.invokeMethod('onHistoryChanged', {
          'webViewId': viewId,
          'canGoBack': args['canGoBack'] as bool,
          'canGoForward': args['canGoForward'] as bool,
        });
      case 'onNavigationStarted':
        webview.onNavigationStarted();
        await _otherIsolateMessageHandler.invokeMethod('onNavigationStarted', {
          'webViewId': viewId,
        });
      case 'onUrlRequested':
        final url = args['url'] as String;
        final ret = webview.notifyUrlChanged(url);
        await _otherIsolateMessageHandler.invokeMethod('onUrlRequested', {
          'webViewId': viewId,
          'url': url,
        });
        return ret;
      case 'onWebMessageReceived':
        final message = args['message'] as String;
        webview.notifyWebMessageReceived(message);
        await _otherIsolateMessageHandler.invokeMethod('onWebMessageReceived', {
          'webViewId': viewId,
          'message': message,
        });
      case 'onNavigationCompleted':
        webview.onNavigationCompleted();
        await _otherIsolateMessageHandler.invokeMethod(
          'onNavigationCompleted',
          {'webViewId': viewId},
        );
      default:
        return;
    }
  }

  /// Clear all cookies and storage.
  static Future<void> clearAll({
    String userDataFolderWindows = 'webview_window_WebView2',
  }) async {
    await _channel.invokeMethod('clearAll');

    if (Platform.isWindows) {
      final Directory webview2Dir;
      if (p.isAbsolute(userDataFolderWindows)) {
        webview2Dir = Directory(userDataFolderWindows);
      } else {
        webview2Dir = Directory(
          p.join(p.dirname(Platform.resolvedExecutable), userDataFolderWindows),
        );
      }

      if (webview2Dir.existsSync()) {
        for (var i = 0; i <= 4; i++) {
          try {
            await webview2Dir.delete(recursive: true);
            break;
          } on Object catch (e) {
            debugPrint('delete cache failed. retring.... $e');
          }
          // wait to ensure all web window has been closed and file handle has been release.
          await Future<void>.delayed(const Duration(seconds: 1));
        }
      }
    }
  }
}
