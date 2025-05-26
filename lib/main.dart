import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'constants/colors.dart';
import 'constants/routes.dart';
import 'screens/auth/auth_wrapper.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/tours/tour_list_screen.dart';
import 'screens/tours/tour_detail_screen.dart'; // Ensure this import is correct
import 'services/auth_service.dart';

void main() {
  runApp(const WanderlustApp());
}

class WanderlustApp extends StatelessWidget {
  const WanderlustApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AuthService())],
      child: MaterialApp(
        title: 'Wanderlust',
        debugShowCheckedModeBanner: false,
        theme: _buildTheme(context), // Pass context to _buildTheme
        initialRoute: Routes.authWrapper,
        routes: {
          Routes.authWrapper: (context) => const AuthWrapper(),
          Routes.login: (context) => const LoginScreen(),
          Routes.register: (context) => const RegisterScreen(),
          Routes.tourList: (context) => const TourListScreen(),
          // Correctly define the route for TourDetailScreen
          Routes.tourDetail: (context) {
            final arguments = ModalRoute.of(context)!.settings.arguments;
            if (arguments is int) {
              // Check if argument is an int (tourId)
              return TourDetailScreen(tourId: arguments);
            }
            // Fallback or error handling if argument is not correct
            // You could navigate to an error page or back to the list
            // For simplicity, returning an error message in a Scaffold
            return const Scaffold(
              backgroundColor: AppColors.background,
              body: Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    "Error: Tour ID not provided or invalid for tour detail page.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            );
          },
          // TODO: Add other routes here if needed
        },
        // It's good practice to have an onUnknownRoute handler
        onUnknownRoute: (settings) {
          return MaterialPageRoute(
            builder:
                (context) => Scaffold(
                  backgroundColor: AppColors.background,
                  appBar: AppBar(
                    title: const Text('Page Not Found'),
                    backgroundColor: AppColors.backgroundSecondary,
                  ),
                  body: Center(
                    child: Text(
                      'Sorry, the page "${settings.name}" could not be found.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
          );
        },
      ),
    );
  }

  ThemeData _buildTheme(BuildContext context) {
    // Added BuildContext parameter
    final baseTheme = ThemeData.dark(); // Start with a base dark theme
    return baseTheme.copyWith(
      brightness: Brightness.dark,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.surface, // Overall background
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.textPrimary,
        onError: Colors.white,
      ),
      textTheme: GoogleFonts.interTextTheme(baseTheme.textTheme).apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.backgroundSecondary,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: GoogleFonts.inter(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface.withOpacity(
          0.7,
        ), // Slightly transparent surface
        hintStyle: TextStyle(color: AppColors.textSecondary.withOpacity(0.8)),
        labelStyle: TextStyle(color: AppColors.textSecondary.withOpacity(0.9)),
        prefixIconColor: AppColors.textSecondary,
        suffixIconColor: AppColors.textSecondary,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: AppColors.border.withOpacity(0.5),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
      ),
      cardTheme: CardTheme(
        elevation:
            0, // Using GlassCard, so native card elevation might not be needed
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: AppColors.backgroundSecondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        contentTextStyle: GoogleFonts.inter(
          fontSize: 16,
          color: AppColors.textSecondary,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.backgroundSecondary.withOpacity(0.95),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
      ),
    );
  }
}
