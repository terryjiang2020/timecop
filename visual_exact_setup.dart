import 'dart:io';
import 'dart:math';

// TODO: Change this to the flutter package name later on.
const String importStatement = "import 'package:androidrouting/visual_exact_button.dart';";
const String openDialog = "showDialog<void>";
const String importTest = 'package:flutter_test/flutter_test.dart';
const popScopeTemplate = """
PopScope(
  onPopInvoked: (didPop) {
    if (didPop) {
      dialogState.closeDialog();
      print('Dialog was dismissed');
    }
  },
  child: 
""";

void main() {
  // Find all Dart files in the current directory and subdirectories
  final directory = Directory.current;
  final dartFiles = directory
      .listSync(recursive: true)
      .where((entity) => entity is File && entity.path.endsWith('.dart'));

  for (var file in dartFiles) {
    processDartFile(file as File);
  }

  print('Script execution completed.');
}

void processDartFile(File file) {

  final lines = file.readAsLinesSync();
  bool containsImport = lines.any((line) => line.contains(importStatement));
  bool noOpenDialog = !lines.any((line) => line.contains(openDialog));
  bool containsTest = lines.any((line) => line.contains(importTest));
  bool isVisualExact = file.path.contains('visual_exact');
  bool modified = false;

  // print('noOpenDialog: $noOpenDialog');
  // print('isVisualExact: $isVisualExact');
  // print('containsTest: $containsTest');

  if (isVisualExact || noOpenDialog || containsTest) {
    // print('Skipping ${file.path}');
    return;
  }

  print('Processing ${file.path}...');

  print('containsImport: $containsImport');

  if (!containsImport) {
    // Add the import statement at the beginning of the file
    lines.insert(0, importStatement);
    modified = true;
  }

  // Find and process each showDialog function
  for (int i = 0; i < lines.length; i++) {
    if (lines[i].contains(openDialog)) {
      final parentFunctionStart = findParentFunctionStart(lines, i);
      final parentFunctionEnd = findParentFunctionEnd(lines, i);

      print('parentFunctionStartLine (i = $parentFunctionStart): ${lines[parentFunctionStart]}');
      print('parentFunctionEndLine (i = $parentFunctionEnd): ${lines[parentFunctionEnd]}');

      if (!containsDialogOpen(lines, parentFunctionStart, parentFunctionEnd)) {
        final uniqueDialogName = generateDialogName();
        lines.insert(i, "dialogState.openDialog('$uniqueDialogName');");
        modified = true;
        i++; // Skip the newly inserted line to avoid processing it again
      }
    }
  }

  // Process onPopInvoked functions
  for (int i = 0; i < lines.length; i++) {
    if (lines[i].contains('onPopInvoked:')) {
      final onPopStart = i;
      final onPopEnd = findParentFunctionEnd(lines, i);

      for (int j = onPopStart; j < onPopEnd; j++) {
        if (lines[j].contains('didPop == true') || lines[j].contains('if (didPop') || lines[j].contains('didPop) {')) {
          if (!lines.sublist(j, onPopEnd).any((line) => line.contains('dialogState.closeDialog('))) {
            lines.insert(j + 1, "dialogState.closeDialog();");
            modified = true;
            break;
          }
        }
      }
    }
  }

  // Find and process each showDialog function
  for (int i = 0; i < lines.length; i++) {
    if (lines[i].contains('showDialog(') || lines[i].contains('showDialog<void>')) {
      final parentFunctionStart = findParentFunctionStart(lines, i);
      final parentFunctionEnd = findParentFunctionEnd(lines, i);

      if (parentFunctionStart != 0) {
        if (!containsDialogOpen(lines, parentFunctionStart, parentFunctionEnd)) {
          final uniqueDialogName = generateDialogName();
          lines.insert(i, "dialogState.openDialog('$uniqueDialogName');");
          modified = true;
          i++; // Skip the newly inserted line to avoid processing it again
        }

        if (!containsPopScope(lines, parentFunctionStart, parentFunctionEnd)) {
          // Wrap the showDialog in PopScope with the onPopInvoked function
          wrapWithPopScope(lines, i);
        }
        else {
          print('PopScope already exists');
          print('parentFunctionStart: $parentFunctionStart');
          print('parentFunctionEnd: $parentFunctionEnd');
          print('i: $i');
        }
      }
    }
  }

  if (modified) {
    file.writeAsStringSync(lines.join('\n'));
    print('Modified ${file.path}');
  }
}

int findParentFunctionStart(List<String> lines, int startIndex) {
  // Reverse search to find the line where the function begins
  // int openParenthesisCount = 0;
  // int closeParenthesisCount = 0;
  int braceCount = 0;

  for (int i = startIndex; i >= 0; i--) {
    String line = lines[i];

    // Look if this line is part of a function body
    braceCount += RegExp(r'\{').allMatches(line).length;
    braceCount -= RegExp(r'\}').allMatches(line).length;

    // If we've passed the function body without finding a function signature, we return this line
    if (braceCount > 0) {
      return i + 1;
    }
  }

  print('Function start not found for line $startIndex');

  return 0; // Default to the start of the file if no function start is found
}


int findParentFunctionEnd(List<String> lines, int startIndex) {
  int openBraces = 0;

  for (int i = startIndex; i < lines.length; i++) {
    if (lines[i].contains('{')) openBraces++;
    if (lines[i].contains('}')) openBraces--;

    if (openBraces == 0) return i;
  }

  print('Function end not found for line $startIndex');
  return lines.length - 1;
}

bool containsDialogOpen(List<String> lines, int start, int end) {
  return lines.sublist(start, end + 1).any((line) => line.contains('dialogState.openDialog('));
}

bool containsPopScope(List<String> lines, int start, int end) {
  return lines.sublist(start, end + 1).any((line) => line.contains('PopScope('));
}

bool containsPopInvoked(List<String> lines, int start, int end) {
  return lines.sublist(start, end + 1).any((line) => line.contains('onPopInvoked:'));
}

String generateDialogName() {
  var random = Random();
  int randomNumber = random.nextInt(1000000); // Generate a random number
  return 'dialog_${DateTime.now().millisecondsSinceEpoch}_$randomNumber';
}

void wrapWithPopScope(List<String> lines, int showDialogIndex) {
  int builderIndex = findBuilderIndex(lines, showDialogIndex);

  if (builderIndex != -1) {
    lines.insert(builderIndex + 1, popScopeTemplate); // Insert PopScope and onPopInvoked
    int closeBracketIndex = findMatchingBracket(lines, builderIndex + 1);
    lines[closeBracketIndex] = removeLastSemicolon(lines[closeBracketIndex]);
    lines.insert(closeBracketIndex + 1, ');'); // Close PopScope after the dialog content
  } else {
    print('Builder not found for showDialog at index $showDialogIndex');
  }
}

int findBuilderIndex(List<String> lines, int startIndex) {
  for (int i = startIndex; i < lines.length; i++) {
    if (lines[i].contains('builder:')) {
      return i;
    }
  }
  return -1;
}

int findMatchingBracket(List<String> lines, int startIndex) {
  int openBrackets = 0;
  bool started = false;
  // print('lines: $lines');

  print('startIndex: $startIndex');
  print('lines.length: ${lines.length}');
  
  for (int i = startIndex; i < lines.length; i++) {
    // print('line: ${lines[i]}');
    if (!lines[i].contains('//')) {
      if (lines[i].contains('(')) {
        // openBrackets += RegExp(r'\(').allMatches(lines[i]).length;
        int allMatchesLeft = RegExp(r'\(').allMatches(lines[i]).length;
        print('allMatchesLeft: $allMatchesLeft');
        openBrackets += allMatchesLeft;
        started = true;
      }
      if (lines[i].contains(')')) {
        // openBrackets -= RegExp(r'\)').allMatches(lines[i]).length;
        int allMatchesRight = RegExp(r'\)').allMatches(lines[i]).length;
        print('allMatchesRight: $allMatchesRight');
        openBrackets -= allMatchesRight;
      }
      if (openBrackets == 0 && started) {
        print('line: ${lines[i]}');
        return i;
      }
    }
    print('i: $i');
  }
  return -1;
}

String removeLastSemicolon(String line) {
  int lastSemicolonIndex = line.lastIndexOf(';');
  
  if (lastSemicolonIndex == -1) {
    // No semicolon found; return the original line
    return line;
  }
  
  // Remove the semicolon by taking substrings before and after it
  return line.substring(0, lastSemicolonIndex) + line.substring(lastSemicolonIndex + 1);
}