import 'dart:async';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:image/image.dart' as img;
import 'package:snake_buddy/discover.dart';
import 'package:snake_buddy/camera.dart';
import 'package:snake_buddy/details.dart';
import 'package:snake_buddy/info.dart';
import 'package:image_picker/image_picker.dart';
import 'package:snake_buddy/helper/tflite_helper.dart';
import 'package:flutter/foundation.dart';

List<CameraDescription> camera = [];

Future<void> main() async {
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError: ${details.exception}');
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('PlatformDispatcher error: $error');
    return true;
  };

  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    try {
      WakelockPlus.enable();
    } catch (e) {
      debugPrint('Error enabling wakelock: $e');
    }

    try {
      camera = await availableCameras();
    } catch (e) {
      debugPrint('Error getting cameras: $e');
      camera = [];
    }

    runApp(const MainApp());
  }, (error, stackTrace) {
    debugPrint('Caught error in runZonedGuarded: $error');
    debugPrint(stackTrace.toString());
  });
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const HomePage(),
      theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.green
          ),
          useMaterial3: true
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<StatefulWidget> createState() => HomePageState();
}

class HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  late TFLiteHelper _tfliteHelper;
  bool isLoading = false;
  String _loadingMessage = "Analyzing Snake...";
  String _processingStage = "Initializing...";

  @override
  void initState() {
    super.initState();
    _tfliteHelper = TFLiteHelper();
    Future.microtask(() => _tfliteHelper.loadModel());
  }

  Future<void> processImage(XFile image) async {
    setState(() {
      isLoading = true;
      _loadingMessage = "Analyzing Snake...";
      _processingStage = "Processing with TensorFlow Lite...";
    });

    try {
      final imageBytes = await image.readAsBytes();

      final img.Image? decodedImage = await compute(
              (Uint8List bytes) => img.decodeImage(bytes),
          Uint8List.fromList(imageBytes)
      );

      if (decodedImage == null) {
        if (mounted) {
          setState(() => isLoading = false);
          _showErrorDialog('Failed to decode image. Please try another image.');
        }
        return;
      }

      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        setState(() {
          _processingStage = "Enhancing results with Gemini AI...";
        });
      }

      final result = await _tfliteHelper.analyzeSnakeImage(decodedImage);

      if (!mounted) return;

      setState(() => isLoading = false);

      if (result.containsKey('error') && result['error'] == true) {
        _showErrorDialog(result['message']);
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DetailsPage(
            result: result,
            capturedImage: MemoryImage(imageBytes),
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error processing image: $e');
      if (mounted) {
        setState(() => isLoading = false);
        _showErrorDialog('Error processing image. Please try again.');
      }
    }
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            "assets/images/forest_background.png",
            fit: BoxFit.cover,
          ),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (_, __, ___) => const InfoPage(),
                      transitionDuration: const Duration(milliseconds: 500),
                      transitionsBuilder: (_, a, __, c) =>
                          FadeTransition(opacity: a, child: c),
                    ),
                  );
                },
                icon: const Icon(Icons.info_outline_rounded, color: Colors.white),
                iconSize: 25,
              ),
            ],
          ),
          body: isLoading
              ? Stack(
            children: [
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.7),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _loadingMessage,
                          style: const TextStyle(
                            fontSize: 24,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _processingStage,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 30),
                        const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ],
          )
              : Padding(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Snake Buddy",
                    style: TextStyle(
                      fontSize: 50,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    "Philippine Snake Identifier",
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 100),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 120,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            onPressed: () async {
                              try {
                                final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                                if (image != null) {
                                  processImage(image);
                                }
                              } catch (e) {
                                debugPrint('Error picking image: $e');
                                _showErrorDialog('Error accessing gallery. Please try again.');
                              }
                            },
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.folder),
                                SizedBox(height: 10),
                                Text("Files"),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: SizedBox(
                          height: 120,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            onPressed: camera.isEmpty
                                ? () => _showErrorDialog('Camera not available on this device.')
                                : () {
                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  pageBuilder: (_, __, ___) => CameraPage(camera: camera.first),
                                  transitionDuration: const Duration(milliseconds: 200),
                                  transitionsBuilder: (_, a, __, c) =>
                                      FadeTransition(opacity: a, child: c),
                                ),
                              );
                            },
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.camera_alt),
                                SizedBox(height: 10),
                                Text("Camera")
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 120,
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (_, __, ___) => const DiscoverPage(),
                            transitionDuration: const Duration(milliseconds: 200),
                            transitionsBuilder: (_, a, __, c) =>
                                FadeTransition(opacity: a, child: c),
                          ),
                        );
                      },
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_outlined),
                          SizedBox(height: 10),
                          Text("Philippine Snakes")
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
