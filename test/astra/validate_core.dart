// Standalone validation script for Astra Core
// Run: dart test/astra/validate_core.dart

// ignore_for_file: avoid_print -- standalone script that reports to stdout.

import 'dart:io';

void main() {
  print('╔═══════════════════════════════════════════════════════════╗');
  print('║       Astra Core - Standalone Validation Test            ║');
  print('╚═══════════════════════════════════════════════════════════╝');
  print('');

  int passed = 0;
  int failed = 0;
  List<String> errors = [];

  // Test 1: Verify all files exist
  print('📁 Checking file existence...');
  final files = [
    'lib/core/astra/astra_core.dart',
    'lib/core/astra/utils/astra_config.dart',
    'lib/core/astra/utils/astra_exception.dart',
    'lib/core/astra/utils/astra_logger.dart',
    'lib/core/astra/models/conversation_model.dart',
    'lib/core/astra/actions/action_models.dart',
    'lib/core/astra/actions/action_dispatcher.dart',
    'lib/core/astra/navigation/app_router.dart',
    'lib/core/astra/controllers/astra_controller.dart',
    'lib/core/astra/repositories/astra_repository.dart',
    'lib/core/astra/services/astra_service.dart',
    'lib/core/astra/widgets/astra_chat_bubble.dart',
    'lib/core/astra/widgets/astra_action_chip.dart',
    'lib/core/astra/providers/astra_provider.dart',
    'lib/features/consultation/astra_chat/astra_chat_page.dart',
    'lib/widgets/astra_ai_button.dart',
  ];

  for (final file in files) {
    final exists = File(file).existsSync();
    if (exists) {
      print('  ✅ $file');
      passed++;
    } else {
      print('  ❌ $file (NOT FOUND)');
      errors.add('Missing file: $file');
      failed++;
    }
  }

  // Test 2: Check file sizes (no file should be empty)
  print('');
  print('📏 Checking file sizes...');
  for (final file in files) {
    final f = File(file);
    if (f.existsSync()) {
      final size = f.readAsStringSync().length;
      if (size < 100) {
        print('  ⚠️  $file (only $size bytes - may be empty)');
        errors.add('Small file: $file');
      } else {
        print('  ✅ $file ($size bytes)');
      }
    }
  }

  // Test 3: Check for common syntax issues
  print('');
  print('🔍 Checking for common issues...');

  final syntaxChecks = [
    // Check conversation_model doesn't have duplicate class
    {
      'file': 'lib/core/astra/models/conversation_model.dart',
      'pattern': 'class AstraAction',
      'shouldContain': false,
      'desc': 'No duplicate AstraAction class'
    },
    // Check astra_chat_page has correct Future.delayed usage
    {
      'file': 'lib/features/consultation/astra_chat/astra_chat_page.dart',
      'pattern': 'await Future.delayed',
      'shouldContain': true,
      'desc': 'Correct Future.delayed usage'
    },
    // Check imports are correct
    {
      'file': 'lib/core/astra/widgets/astra_chat_bubble.dart',
      'pattern':
          "import 'package:doctro/core/astra/actions/action_models.dart'",
      'shouldContain': true,
      'desc': 'Has action_models import'
    },
  ];

  for (final check in syntaxChecks) {
    final f = File(check['file'] as String);
    if (!f.existsSync()) continue;

    final content = f.readAsStringSync();
    final contains = content.contains(check['pattern'] as String);
    final shouldContain = check['shouldContain'] as bool;

    if (contains == shouldContain) {
      print('  ✅ ${check['desc']}');
      passed++;
    } else {
      print('  ❌ ${check['desc']}');
      errors.add('${check['file']}: ${check['desc']}');
      failed++;
    }
  }

  // Test 4: Check for TODO/FIXME comments
  print('');
  print('📝 Checking for TODOs...');
  int todoCount = 0;
  for (final file in files) {
    final f = File(file);
    if (!f.existsSync()) continue;

    final content = f.readAsStringSync();
    final todos = RegExp(r'(TODO|FIXME|HACK|XXX)').allMatches(content);
    todoCount += todos.length;
  }
  print('  Found $todoCount TODO/FIXME comments');

  // Test 5: Count total lines
  print('');
  print('📊 Statistics:');
  int totalLines = 0;
  int totalFiles = 0;
  for (final file in files) {
    final f = File(file);
    if (!f.existsSync()) continue;

    final lines = f.readAsStringSync().split('\n').length;
    totalLines += lines;
    totalFiles++;
  }
  print('  Total files: $totalFiles');
  print('  Total lines: $totalLines');
  print('  Average lines per file: ${(totalLines / totalFiles).round()}');

  // Summary
  print('');
  print('╔═══════════════════════════════════════════════════════════╗');
  print('║                    SUMMARY                               ║');
  print('╠═══════════════════════════════════════════════════════════╣');
  print('║  ✅ Passed: $passed                                      ║');
  print('║  ❌ Failed: $failed                                      ║');
  print('╚═══════════════════════════════════════════════════════════╝');

  if (errors.isNotEmpty) {
    print('');
    print('Errors:');
    for (final error in errors) {
      print('  - $error');
    }
  }

  print('');
  if (failed == 0) {
    print('🎉 All validations passed!');
    exit(0);
  } else {
    print('⚠️  Some validations failed. Please review.');
    exit(1);
  }
}
