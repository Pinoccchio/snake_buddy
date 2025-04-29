import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img; // Package for image decoding
import 'package:snake_buddy/details.dart';
import 'package:snake_buddy/helper/gemini_helper.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key, required this.camera});

  final CameraDescription camera;

  @override
  State<StatefulWidget> createState() => CameraPageState();
}

class CameraPageState extends State<CameraPage> {
  late CameraController _controller;
  late GeminiHelper _geminiHelper;
  bool isLoading = false;
  bool disableZoom = true;
  Uint8List? capturedImageBytes;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.veryHigh,
      enableAudio: false,
    );

    _controller.initialize().then((_) {
      if (mounted) {
        setState(() {});
        _controller.setExposureOffset(0.5);
        _controller.setFlashMode(FlashMode.auto);
        if (disableZoom) {
          _controller.setZoomLevel(1.0);
        }
      }
    }).catchError((e) {
      debugPrint("Error initializing camera: $e");
    });

    _geminiHelper = GeminiHelper();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> captureAndProcessImage(BuildContext context) async {
    setState(() => isLoading = true);

    try {
      final XFile picture = await _controller.takePicture();
      final imageBytes = await picture.readAsBytes();
      capturedImageBytes = imageBytes;

      final img.Image? decodedImage = img.decodeImage(Uint8List.fromList(imageBytes));

      if (decodedImage == null) {
        setState(() => isLoading = false);
        _showErrorDialog('Failed to decode image');
        return;
      }

      // Resize image for API processing
      final img.Image resizedImage = img.copyResize(decodedImage, width: 512, height: 512);

      // Process with Gemini API
      final result = await _geminiHelper.analyzeSnakeImage(resizedImage);

      setState(() => isLoading = false);

      if (mounted) {
        if (result.containsKey('error') && result['error'] == true) {
          _showErrorDialog(result['message']);
          return;
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailsPage(
              result: result,
              capturedImage: MemoryImage(capturedImageBytes!),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      _showErrorDialog('Error: ${e.toString()}');
    }
  }

  void _showErrorDialog(String message) {
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
            "assets/images/image.png",
            fit: BoxFit.cover,
          ),
        ),
        Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            automaticallyImplyLeading: false,
          ),
          extendBodyBehindAppBar: true,
          backgroundColor: Colors.transparent,
          body: isLoading
              ? Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  'assets/images/background.png',
                  fit: BoxFit.cover,
                ),
              ),
              const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Analyzing Snake...",
                      style: TextStyle(
                        fontSize: 24,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      "Identifying Philippine Species",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 30),
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    )
                  ],
                ),
              ),
            ],
          )
              : Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: CameraPreview(_controller),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => captureAndProcessImage(context),
                  style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(20),
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    size: 30,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
