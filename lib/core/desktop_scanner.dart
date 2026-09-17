import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import '../models/companion_model.dart';

class DesktopItem {
  final String path;
  final String name;
  final bool isDirectory;
  final String extension;
  final int sizeBytes;

  const DesktopItem({
    required this.path,
    required this.name,
    required this.isDirectory,
    required this.extension,
    required this.sizeBytes,
  });
}

class DesktopScanner {
  static String get desktopPath {
    if (Platform.isWindows) {
      final userProfile = Platform.environment['USERPROFILE'] ?? 'C:\\Users\\Default';
      return p.join(userProfile, 'Desktop');
    } else {
      final home = Platform.environment['HOME'] ?? '/';
      return p.join(home, 'Desktop');
    }
  }

  static Future<List<DesktopItem>> scanDesktop() async {
    final List<DesktopItem> results = [];
    try {
      final dir = Directory(desktopPath);
      if (!await dir.exists()) {
        return results;
      }

      await for (final entity in dir.list(followLinks: false)) {
        final name = p.basename(entity.path);
        // Skip hidden files/directories like .DS_Store
        if (name.startsWith('.')) continue;

        bool isDir = entity is Directory;
        int size = 0;
        if (!isDir) {
          try {
            final stat = await entity.stat();
            size = stat.size;
          } catch (_) {}
        }

        results.add(DesktopItem(
          path: entity.path,
          name: name,
          isDirectory: isDir,
          extension: isDir ? '' : p.extension(name).toLowerCase(),
          sizeBytes: size,
        ));
      }
    } catch (e) {
      debugPrint('DesktopScanner error scanning desktop: $e');
    }

    // Sort: directories first, then alphabetical
    results.sort((a, b) {
      if (a.isDirectory && !b.isDirectory) return -1;
      if (!a.isDirectory && b.isDirectory) return 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return results;
  }

  static String generateSniffReaction(DesktopItem item, CompanionModel companion) {
    final ext = item.extension;

    // Check if it's the companion's favorite extension
    if (companion.favoriteFileExtensions.contains(ext)) {
      return '⭐ *sniff sniff* "OMG! My FAVORITE file type: ${item.name}! Smells delicious!"';
    }

    if (item.isDirectory) {
      final folderReactions = [
        '📁 *sniff sniff* "A cavernous folder: ${item.name}! Perfect place for a secret burrow!"',
        '📁 *peeks into ${item.name}* "Whoa, look at all the files hiding in here!"',
        '📁 *paws at ${item.name}* "Can I jump inside? I bet there are treasures!"',
      ];
      return folderReactions[DateTime.now().millisecond % folderReactions.length];
    }

    switch (ext) {
      case '.png':
      case '.jpg':
      case '.jpeg':
      case '.gif':
      case '.webp':
      case '.svg':
        return '🎨 *sniff sniff* "${item.name}" smells colorful! Did you create this masterpiece?';

      case '.dart':
      case '.js':
      case '.ts':
      case '.py':
      case '.cpp':
      case '.html':
      case '.css':
      case '.json':
        return '💻 *sniff sniff* "${item.name}"... crunchy syntax! Let me know if there are bugs to catch!';

      case '.pdf':
      case '.docx':
      case '.doc':
      case '.txt':
      case '.md':
        return '📜 *sniff sniff* "${item.name}"... smells like important paperwork or a cozy bedtime story!';

      case '.mp3':
      case '.wav':
      case '.flac':
      case '.m4a':
        return '🎵 *perks ears up* "${item.name}"... vibrating with sweet desktop melodies!';

      case '.zip':
      case '.tar':
      case '.gz':
      case '.rar':
        return '📦 *taps with paw* "${item.name}"... a tightly packed treasure chest!';

      default:
        return '✨ *sniff sniff* "${item.name}"... fascinating mystery item on our desktop!';
    }
  }

  static Future<void> openOrReveal(DesktopItem item) async {
    try {
      if (Platform.isMacOS) {
        await Process.run('open', ['-R', item.path]);
      } else if (Platform.isWindows) {
        await Process.run('explorer.exe', ['/select,${item.path}']);
      }
    } catch (e) {
      debugPrint('Error opening or revealing desktop item: $e');
    }
  }
}
