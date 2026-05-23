import 'dart:io';

void main() async {
  final directory = Directory('assets/icons/banks');
  final files = directory.listSync().whereType<File>().where((f) => f.path.endsWith('.svg'));
  
  for (var file in files) {
    String content = await file.readAsString();
    
    // Find style block
    final styleRegex = RegExp(r'<style[^>]*>([\s\S]*?)</style>');
    final styleMatch = styleRegex.firstMatch(content);
    
    if (styleMatch != null) {
      String styleContent = styleMatch.group(1) ?? '';
      
      // Extract class definitions, e.g. .cls-1 { fill: #518df8; } or .st0{fill:#FF3E17;}
      final classRegex = RegExp(r'\.([a-zA-Z0-9_-]+)\s*\{\s*fill\s*:\s*(#[a-fA-F0-9]+)[^}]*\}');
      final classMatches = classRegex.allMatches(styleContent);
      
      for (var cm in classMatches) {
        String className = cm.group(1)!;
        String color = cm.group(2)!;
        
        // Replace class="className" with fill="color"
        // Also handle cases where it might be in a list of classes, though usually it's single
        content = content.replaceAll('class="$className"', 'fill="$color"');
      }
      
      // Remove the style block, defs, sodipodi:namedview, metadata
      content = content.replaceAll(styleRegex, '');
    }
    
    content = content.replaceAll(RegExp(r'<sodipodi:namedview[\s\S]*?/>'), '');
    content = content.replaceAll(RegExp(r'<metadata[\s\S]*?</metadata>'), '');
    content = content.replaceAll(RegExp(r'<metadata[\s\S]*?/>'), '');
    
    await file.writeAsString(content);
    print('Processed: ${file.path}');
  }
}
