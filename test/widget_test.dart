import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kapanbasi/main.dart';

void main() {
  // Menonaktifkan pengambilan font dari internet selama pengujian
  GoogleFonts.config.allowRuntimeFetching = false;

  // Menginisialisasi dotenv kosong agar isSupabaseConfigured bernilai false 
  // dan menghindari pemanggilan Supabase.instance sebelum terinisialisasi
  dotenv.loadFromString(envString: '');

  testWidgets('KapanBasi initial layout test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: MyApp(isSupabaseConfigured: false),
      ),
    );

    // Menunggu seluruh state rendering selesai
    await tester.pumpAndSettle();

    // Memastikan judul logo aplikasi 'KapanBasi?' dirender di halaman login
    expect(find.text('KapanBasi?'), findsOneWidget);

    // Memastikan tombol 'Masuk' ada pada form login
    expect(find.text('Masuk'), findsOneWidget);
  });
}
