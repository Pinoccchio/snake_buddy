import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:snake_buddy/details.dart';
import 'package:snake_buddy/helper/tflite_helper.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key, required this.camera});

  final CameraDescription camera;

  @override
  State<StatefulWidget> createState() => CameraPageState();
}

class CameraPageState extends State<CameraPage> with WidgetsBindingObserver {
  late CameraController _controller;
  late TFLiteHelper _tfliteHelper;
  bool isLoading = false;
  bool disableZoom = true;
  Uint8List? capturedImageBytes;
  String _loadingMessage = "Analyzing Snake...";
  String _processingStage = "Initializing...";
  bool _isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
    _tfliteHelper = TFLiteHelper();
    _tfliteHelper.loadModel();
  }

  Future<void> _initializeCamera() async {
    try {
      _controller = CameraController(
        widget.camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller.initialize();

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });

        try {
          await _controller.setExposureOffset(0.5);
        } catch (e) {
          debugPrint("Error setting exposure: $e");
        }

        try {
          await _controller.setFlashMode(FlashMode.auto);
        } catch (e) {
          debugPrint("Error setting flash mode: $e");
        }

        if (disableZoom) {
          try {
            await _controller.setZoomLevel(1.0);
          } catch (e) {
            debugPrint("Error setting zoom level: $e");
          }
        }
      }
    } catch (e) {
      debugPrint("Error initializing camera: $e");
      _showErrorDialog('Camera initialization failed. Please restart the app.');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_isCameraInitialized) return;

    if (state == AppLifecycleState.inactive) {
      _controller.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    _tfliteHelper.closeModel();
    super.dispose();
  }

  Future<void> captureAndProcessImage(BuildContext context) async {
    if (!_isCameraInitialized) {
      _showErrorDialog('Camera is not ready. Please wait or restart the app.');
      return;
    }

    setState(() {
      isLoading = true;
      _loadingMessage = "Analyzing Snake...";
      _processingStage = "Capturing image...";
    });

    try {
      await Future.delayed(const Duration(milliseconds: 100));

      final XFile picture = await _controller.takePicture();
      final imageBytes = await picture.readAsBytes();
      capturedImageBytes = imageBytes;

      setState(() {
        _processingStage = "Processing with TensorFlow Lite...";
      });

      final img.Image? decodedImage = img.decodeImage(Uint8List.fromList(imageBytes));

      if (decodedImage == null) {
        setState(() => isLoading = false);
        _showErrorDialog('Failed to decode image. Please try again.');
        return;
      }

      await Future.delayed(const Duration(milliseconds: 500));

      setState(() {
        _processingStage = "Enhancing results with Gemini AI...";
      });

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
            capturedImage: MemoryImage(capturedImageBytes!),
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        _showErrorDialog('Error: ${e.toString()}');
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
              Center(
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
            ],
          )
              : Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: _isCameraInitialized
                      ? CameraPreview(_controller)
                      : Container(
                    height: 300,
                    color: Colors.black,
                    child: const Center(
                      child: Text(
                        "Initializing camera...",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isCameraInitialized
                      ? () => captureAndProcessImage(context)
                      : null,
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
