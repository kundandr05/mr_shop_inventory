import 'dart:html' as html;

void downloadCsvWeb(String csvData, String filename) {
  final blob = html.Blob([csvData], 'text/csv');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..click();
  html.Url.revokeObjectUrl(url);
}
