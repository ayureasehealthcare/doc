import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:doctro/features/prescription/pdf_creation/pdf_viewer_page.dart';
import 'package:doctro/widgets/osler_state_view.dart';

void main() {
  testWidgets('PDF viewer with no file shows the kit empty state',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: PdfViewerPage()));

    expect(find.byType(OslerStateView), findsOneWidget);
    expect(find.text('No PDF document loaded'), findsOneWidget);
    expect(find.text('PDF Preview'), findsOneWidget);
  });
}
