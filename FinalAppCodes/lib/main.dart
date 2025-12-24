import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

import 'providers/classifier_provider.dart' as cp;
import 'providers/history_provider.dart';
import 'providers/class_provider.dart';
import 'providers/theme_provider.dart';
import 'models/history_item.dart';
import 'screens/history_screen.dart';
import 'screens/class_info_screen.dart';
import 'screens/detect_screen.dart';
import 'screens/analytics_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => cp.ClassifierProvider()),
        ChangeNotifierProvider(create: (_) => HistoryProvider()),
        ChangeNotifierProvider(create: (_) => ClassProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Builder(
        builder: (context) {
          final themeProv = Provider.of<ThemeProvider>(context);
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'TFLite Snake Species Classifier',
            theme: ThemeData(primarySwatch: Colors.deepPurple),
            darkTheme: ThemeData.dark(),
            themeMode: themeProv.mode,
            home: const HomePage(),
          );
        },
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // results are shown on Detect screen; don't keep unused field here
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // ignore: use_build_context_synchronously
    final classifierProv = Provider.of<cp.ClassifierProvider>(
      context,
      listen: false,
    );
    // ignore: use_build_context_synchronously
    final hp = Provider.of<HistoryProvider>(context, listen: false);
    // ensure classes are loaded for the home screen
    // ignore: use_build_context_synchronously
    final classProv = Provider.of<ClassProvider>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      classifierProv.init();
      hp.init();
      classProv.loadClasses();
    });
  }

  Future<void> _pick(ImageSource src) async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(source: src, imageQuality: 85);
    if (!mounted) return;
    if (xfile == null) return;
    final file = File(xfile.path);

    final classifierProv = Provider.of<cp.ClassifierProvider>(
      context,
      listen: false,
    );
    final hp = Provider.of<HistoryProvider>(context, listen: false);

    final saved = await classifierProv.saveImageToAppDir(file);
    final results = await classifierProv.classifyFile(saved);

    final top = results.first;
    final item = HistoryItem(
      label: top['label'],
      confidence: (top['confidence'] as double),
      imagePath: saved.path,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
    await hp.add(item);
    // After saving history and classification, open the Detect screen to show results
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetectScreen(imagePath: saved.path, results: results),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Snake Species Classifier'),
        actions: [
          // Light mode button
          Consumer<ThemeProvider>(
            builder: (context, t, _) {
              final active = !t.isDark;
              return IconButton(
                icon: Icon(
                  Icons.light_mode,
                  color: active
                      ? Theme.of(context).colorScheme.secondary
                      : null,
                ),
                tooltip: 'Light',
                onPressed: t.isDark ? t.setLight : null,
              );
            },
          ),
          // Dark mode button
          Consumer<ThemeProvider>(
            builder: (context, t, _) {
              final active = t.isDark;
              return IconButton(
                icon: Icon(
                  Icons.dark_mode,
                  color: active
                      ? Theme.of(context).colorScheme.secondary
                      : null,
                ),
                tooltip: 'Dark',
                onPressed: t.isDark ? null : t.setDark,
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: ListView(
          padding: const EdgeInsets.only(bottom: 96),
          children: [
            const SizedBox(height: 12),
            // Classes grid
            Consumer<ClassProvider>(
              builder: (context, cpv, _) {
                final classes = cpv.classes;
                if (classes.isEmpty) return const SizedBox.shrink();
                final width = MediaQuery.of(context).size.width;
                final cross = width > 600 ? 4 : 2;
                return GridView.count(
                  crossAxisCount: cross,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 0.95,
                  children: classes.map((c) {
                    return Card(
                      color: const Color(
                        0xFFF7F2F8,
                      ), // subtle lavender card background
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: InkWell(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ClassInfoScreen(cactusClass: c),
                          ),
                        ),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(
                                child: Container(
                                  width: 72,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFFEDE6FB,
                                    ), // pale lavender icon bg
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: c.hasImage
                                        ? ClipOval(
                                            child: c.isAssetImage
                                                ? Image.asset(
                                                    c.effectiveImage!,
                                                    width: 56,
                                                    height: 56,
                                                    fit: BoxFit.cover,
                                                  )
                                                : Image.file(
                                                    File(c.effectiveImage!),
                                                    width: 56,
                                                    height: 56,
                                                    fit: BoxFit.cover,
                                                  ),
                                          )
                                        : Icon(
                                            c.icon,
                                            size: 36,
                                            color: Theme.of(
                                              context,
                                            ).primaryColor,
                                          ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                c.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Expanded(
                                child: Text(
                                  c.description,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildBottomNavigation() {
    const selectedBg = Color(0xFFDFF7E5); // pale green
    const selectedIcon = Color(0xFF2E7D32);
    const unselectedColor = Colors.black54;

    Widget item(IconData icon, String label, int idx) {
      final selected = _currentIndex == idx;
      return Expanded(
        child: GestureDetector(
          onTap: () {
            // Centralize handling for clarity and add debug logs
            _handleBottomNavTap(idx);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: selected
                    ? BoxDecoration(
                        color: selectedBg,
                        borderRadius: BorderRadius.circular(24),
                      )
                    : null,
                child: Icon(
                  icon,
                  size: 20,
                  color: selected ? selectedIcon : unselectedColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: selected ? selectedIcon : unselectedColor,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SafeArea(
      child: Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Color(0x11000000),
              blurRadius: 6,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            item(Icons.home, 'Home', 0),
            item(Icons.bolt, 'Detect', 1),
            item(Icons.history, 'History', 2),
            item(Icons.show_chart, 'Analytics', 3),
          ],
        ),
      ),
    );
  }

  void _handleBottomNavTap(int idx) {
    setState(() => _currentIndex = idx);
    if (idx == 1) {
      // Show choice: Camera or Gallery when Detect is tapped
      debugPrint('Detect tapped - showing choice sheet');
      showModalBottomSheet(
        context: context,
        builder: (ctx) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Camera'),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    debugPrint('Detect choice: Camera');
                    // ignore: use_build_context_synchronously
                    _pick(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Gallery'),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    debugPrint('Detect choice: Gallery');
                    // ignore: use_build_context_synchronously
                    _pick(ImageSource.gallery);
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          );
        },
      ).whenComplete(() => debugPrint('Detect sheet dismissed'));

      // As a fallback for devices where bottom sheet might not appear, also show
      // a simple dialog (does not fire if bottom sheet is visible immediately).
      Future.delayed(const Duration(milliseconds: 300), () {
        // If the sheet was dismissed quickly (or not shown), present a dialog as fallback
        if (!mounted) return;
        // We check if Navigator has any modal routes; if not, show dialog fallback
        final hasModal = ModalRoute.of(context)?.isCurrent == false;
        if (!hasModal) {
          debugPrint('Detect sheet not visible - showing dialog fallback');
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Choose source'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    debugPrint('Dialog choice: Camera');
                    _pick(ImageSource.camera);
                  },
                  child: const Text('Camera'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    debugPrint('Dialog choice: Gallery');
                    _pick(ImageSource.gallery);
                  },
                  child: const Text('Gallery'),
                ),
              ],
            ),
          );
        }
      });
    } else if (idx == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const HistoryScreen()),
      );
    } else if (idx == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => AnalyticsScreen()),
      );
    }
  }
}
