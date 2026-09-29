import 'dart:io';

void main() {
  final file = File('lib/core/config/google_sheets_config.dart');
  String content = file.readAsStringSync();
  
  // The error is caused because the private key string spans multiple lines physically.
  // We need to remove actual newlines that appear inside the JSON string value for private_key.
  // The easiest way is to find the private_key value and remove the physical newlines (\r\n or \n) 
  // that are NOT escaped \n.
  
  // Actually, since I have the credentials in the file, let me just replace all physical newlines 
  // between "private_key": " and ", with nothing, while preserving \n literals.
  
  // Let's just fix the entire JSON string.
  int startIndex = content.indexOf('\'\'\'{');
  int endIndex = content.lastIndexOf('\'\'\';');
  
  if (startIndex != -1 && endIndex != -1) {
    String beforeJson = content.substring(0, startIndex + 3);
    String jsonStr = content.substring(startIndex + 3, endIndex);
    String afterJson = content.substring(endIndex);
    
    // Now we clean up the jsonStr. The problem is physical newlines inside "MIIE... "
    // Let's use regex to find the private_key value.
    final RegExp keyRegex = RegExp(r'"private_key"\s*:\s*"([^"]+)"', multiLine: true);
    
    jsonStr = jsonStr.replaceAllMapped(keyRegex, (match) {
      String keyContent = match.group(1)!;
      // Remove physical newlines
      keyContent = keyContent.replaceAll('\r', '').replaceAll('\n', '');
      // Ensure the \n literals are properly escaped for dart multiline strings
      // Wait, if we use ''' it interprets \n as a newline. We need to escape it as \\n
      // so json.decode gets the literal \n.
      keyContent = keyContent.replaceAll(r'\n', r'\\n');
      return '"private_key": "$keyContent"';
    });
    
    file.writeAsStringSync(beforeJson + jsonStr + afterJson);
    print("Fixed JSON in config file.");
  } else {
    print("Could not find ''' boundaries.");
  }
}
