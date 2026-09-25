import 'dart:js' as js;

Future<void> promptPwaInstall() async {
  if (js.context.hasProperty('promptInstall')) {
    js.context.callMethod('promptInstall');
  }
}
