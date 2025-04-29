import 'dart:io';
import 'dart:isolate';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as image_lib;
import 'package:snake_buddy/image_utils.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class IsolateInference {
  static const String _debugName = "TFLITE_INFERENCE";
  final ReceivePort _receivePort = ReceivePort();
  late Isolate _isolate;
  late SendPort _sendPort;

  SendPort get sendPort => _sendPort;

  Future<void> start() async {
    _isolate = await Isolate.spawn<SendPort>(entryPoint, _receivePort.sendPort,
        debugName: _debugName);
    _sendPort = await _receivePort.first;
  }

  Future<void> close() async {
    _isolate.kill();
    _receivePort.close();
  }

  static void entryPoint(SendPort sendPort) async {
    final port = ReceivePort();
    sendPort.send(port.sendPort);

    await for (final InferenceModel isolateModel in port) {
      try {
        image_lib.Image? img;
        if (isolateModel.isCameraFrame()) {
          img = ImageUtils.convertCameraImage(isolateModel.cameraImage!);
        } else {
          img = isolateModel.image;
        }

        if (img == null) {
          debugPrint("ERROR: Failed to process image.");
          continue;
        }

        // Resize the image to match the model input shape
        image_lib.Image imageInput = image_lib.copyResize(
          img,
          width: isolateModel.inputShape[1],
          height: isolateModel.inputShape[2],
        );

        // Rotate if necessary (Android Camera Issue)
        if (Platform.isAndroid && isolateModel.isCameraFrame()) {
          imageInput = image_lib.copyRotate(imageInput, angle: 90);
        }

        // Convert image to float tensor (0-1 range)
        final imageMatrix = List.generate(
          imageInput.height,
          (y) => List.generate(
            imageInput.width,
            (x) {
              final pixel = imageInput.getPixel(x, y);
              return [pixel.r / 255.0, pixel.g / 255.0, pixel.b / 255.0];
            },
          ),
        );

        // Ensure proper input shape for TensorFlow Lite model
        final input = [imageMatrix]; // Shape: [1, height, width, 3]
        final output = [List<double>.filled(isolateModel.outputShape[1], 0.0)];

        debugPrint("Running model inference...");
        Interpreter interpreter =
            Interpreter.fromAddress(isolateModel.interpreterAddress);
        interpreter.run(input, output);

        final result = output.first;

        // Get highest confidence score
        double maxScore = result.reduce((a, b) => a > b ? a : b);
        int bestIndex = result.indexOf(maxScore);

        String bestLabel = bestIndex < isolateModel.labels.length
            ? isolateModel.labels[bestIndex]
            : "Unknown";

        debugPrint("Best Label: $bestLabel, Score: $maxScore");

        // Map labels to confidence scores
        var classification = <String, double>{};
        for (var i = 0; i < result.length; i++) {
          if (i < isolateModel.labels.length) {
            classification[isolateModel.labels[i]] = result[i];
          }
        }

        debugPrint("Classification Results: $classification");

        // Send back results
        isolateModel.responsePort.send(classification);
      } catch (e, stacktrace) {
        debugPrint("ERROR during inference: $e");
        debugPrint(stacktrace.toString());
      }
    }
  }
}

class InferenceModel {
  CameraImage? cameraImage;
  image_lib.Image? image;
  int interpreterAddress;
  List<String> labels;
  List<int> inputShape;
  List<int> outputShape;
  late SendPort responsePort;

  InferenceModel(this.cameraImage, this.image, this.interpreterAddress,
      this.labels, this.inputShape, this.outputShape);

  bool isCameraFrame() {
    return cameraImage != null;
  }
}
