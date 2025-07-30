# desktop_webview_linux

Webview on Linux using webkit2gtk. desktop_webview_window only Linux part.

## Getting Started

1. modify your `main` method.
   ```dart
   import 'package:desktop_webview_linux/desktop_webview_linux.dart';
   
   void main() async {
     WidgetsFlutterBinding.ensureInitialized();
     
     // Add this your main method.
     // used to show a webview title bar.
     if (runWebViewTitleBarWidget(args)) {
       return;
     }
   
     runApp(MyApp());
   }
   
   ```

2. launch WebViewWindow

   ```dart
     final webview = await WebviewWindow.create();
     webview.launch("https://example.com");
   ```

## linux requirement

In Ubuntu/Debian:
```shell
sudo apt-get install libwebkit2gtk-4.1-0 libwebkit2gtk-4.1-dev libsoup-3.0-0 libsoup-3.0-dev
```

In Fedora/RPM:
```shell
sudo dnf install webkit2gtk4.1 webkit2gtk4.1-devel libsoup3 libsoup3-devel
```
