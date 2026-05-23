import 'dart:io';

void main() async {
  final directory = Directory('assets/icons/banks');
  final files = directory.listSync().whereType<File>().where((f) => f.path.endsWith('.svg'));
  
  // Colors to replace with white
  final darkColors = [
    '#000000', '#020000', '#111111', '#1a1a1a', '#222222', '#333333', 'black',
    '#0A3967', // Mandiri dark blue
    '#002561', // Another dark blue
  ];
  
  for (var file in files) {
    String content = await file.readAsString();
    bool changed = false;
    
    // Also find any fill="#xxxxxx" and if it's black/dark gray, make it white.
    // We can use a regex to find all fills.
    final fillRegex = RegExp(r'fill="([^"]+)"', caseSensitive: false);
    content = content.replaceAllMapped(fillRegex, (match) {
      String color = match.group(1)!.toLowerCase();
      if (darkColors.contains(color) || (color.startsWith('#') && color.length == 7 && _isVeryDark(color))) {
        changed = true;
        return 'fill="#FFFFFF"';
      }
      return match.group(0)!;
    });

    // Handle fill: #xxxxxx
    final fillStyleRegex = RegExp(r'fill:\s*([^;"]+)', caseSensitive: false);
    content = content.replaceAllMapped(fillStyleRegex, (match) {
      String color = match.group(1)!.toLowerCase().trim();
      if (darkColors.contains(color) || (color.startsWith('#') && color.length == 7 && _isVeryDark(color))) {
        changed = true;
        return 'fill: #FFFFFF';
      }
      return match.group(0)!;
    });
    
    if (changed) {
      await file.writeAsString(content);
      print('Fixed colors in: ${file.path}');
    }
  }
}

bool _isVeryDark(String hexColor) {
  if (hexColor.length != 7) return false;
  try {
    int r = int.parse(hexColor.substring(1, 3), radix: 16);
    int g = int.parse(hexColor.substring(3, 5), radix: 16);
    int b = int.parse(hexColor.substring(5, 7), radix: 16);
    
    // Calculate relative luminance
    double luminance = (0.299 * r + 0.587 * g + 0.114 * b) / 255;
    
    // If it's very dark (almost black), return true.
    // We don't want to replace actual brand colors like dark blue or red unless it's extremely dark.
    return luminance < 0.05; 
  } catch (e) {
    return false;
  }
}
