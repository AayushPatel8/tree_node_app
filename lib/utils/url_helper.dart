import 'package:url_launcher/url_launcher.dart';

class UrlHelper {
  static Future<void> openGitHub() async {
    const String githubUrl = 'https://github.com/AayushPatel8/tree_node_app';
    final uri = Uri.parse(githubUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw Exception('Could not open the link.');
    }
  }
}