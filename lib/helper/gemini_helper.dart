import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image/image.dart' as img;

class GeminiHelper {
  static const String _apiKey = "AIzaSyDwnVkCEvCL9VtPxy84tQ3QrU3QhiUH3oM";
  static const String _modelName = 'gemini-1.5-pro';

  GenerativeModel? _model;

  GenerativeModel _getModel() {
    _model ??= GenerativeModel(
      model: _modelName,
      apiKey: _apiKey,
    );
    return _model!;
  }

  Future<Map<String, dynamic>> analyzeSnakeImage(img.Image image) async {
    try {
      final bytes = await compute(_encodePngIsolate, image);

      final String enhancementQuery = _getEnhancementQuery();

      final imagePart = DataPart('image/png', bytes);
      final textPart = TextPart(enhancementQuery);
      final content = [Content.multi([textPart, imagePart])];

      final response = await _getModel().generateContent(content)
          .timeout(const Duration(seconds: 10), onTimeout: () {
        throw TimeoutException('API request timed out');
      });

      final responseText = response.text ?? '';

      debugPrint('Processing response data...');

      try {
        final jsonRegExp = RegExp(r'{[\s\S]*}');
        final match = jsonRegExp.firstMatch(responseText);

        if (match != null) {
          final jsonStr = match.group(0);
          if (jsonStr != null) {
            return Map<String, dynamic>.from(await _parseJson(jsonStr));
          }
        }

        return Map<String, dynamic>.from(await _parseJson(responseText));

      } catch (e) {
        debugPrint('Error parsing response data: $e');
        return _getDefaultResponse();
      }
    } catch (e) {
      debugPrint('Error in analysis process: $e');
      return _getDefaultResponse();
    }
  }

  String _getEnhancementQuery() {
    final List<String> parts = [
      "Analyze the image and identify the species shown. ",
      "Consider these categories: ",
      _getSpeciesList(),
      "If identification is not possible, use 'Random' as the name. ",
      "Return data in this format: ",
      _getResponseFormat()
    ];

    return parts.join("");
  }

  String _getSpeciesList() {
    const String encoded = "QWxiaW5vIEJ1cm1lc2UgUHl0aG9uLCBBc2lhbiBTdW5iZWFtIFNuYWtlLCBCYW5kZWQgTWFsYXlzaWFuLCBCbHVlLUxpcHBlZCBTZWEgS3JhaXQsIEJsdW50aGVhZCBTbHVnIFNuYWtlLCBDaGluZXNlIFNlYSBLcmFpdCwgQ29tbW9uIE1vY2sgVmlwZXIsIENvcmFsIFNuYWtlLCBEb2ctVG9vdGhlZCBDYXQgU25ha2UsIEdvbGQtUmluZ2VkIENhdCBTbmFrZSwgR3JlZW4gVHJlZSBQeXRob24sIEtpbmcgQ29icmEsIE1hcmluZSBGaWxlIFNuYWtlLCBPcmllbnRhbCBXaGlwc25ha2UsIE9ybmF0ZSBTZWEgU25ha2UsIFBhaW50ZWQgQnJvbnplYmFjaywgUGFyYWRpc2UgRmx5aW5nIFNuYWtlLCBQaGlsaXBwaW5lIFBpdCBWaXBlciwgUGhpbGlwcGluZSBTaHJ1YiBTbmFrZSwgUmVkLVRhaWxlZCBHcmVlbiBSYXRzbmFrZSwgUmV0aWN1bGF0ZWQgUHl0aG9uLCBTYW1hciBDb2JyYSwgU3BlY2tsZWJlbGx5IEtlZWxiYWNrLCBZZWxsb3ctQmVsbGllZCBTZWEgU25ha2U=";
    return utf8.decode(base64.decode(encoded));
  }

  String _getResponseFormat() {
    final Map<String, dynamic> format = {
      "name": "Common Name",
      "scientific_name": "Genus species",
      "venomous": "true/false",
      "description": "Brief description",
      "classification": {
        "size": "Size description",
        "color_pattern": "Color description",
        "distinct_feature": "Notable features"
      },
      "conservation_status": "Status",
      "marine": "true/false",
      "habitat": "Habitat info",
      "geographic_range": "Distribution",
      "behavior": "Behavior",
      "diet": "Diet"
    };

    return "JSON format: ${jsonEncode(format)}";
  }

  Map<String, dynamic> _getDefaultResponse() {
    return {
      "name": "Random",
      "scientific_name": "Unidentified species",
      "venomous": false,
      "description": "The image could not be identified as one of the known Philippine snake species. It may be a different species, a poor quality image, or not a snake at all.",
      "classification": {
        "size": "Unknown",
        "color_pattern": "Unknown",
        "distinct_feature": "Unknown"
      },
      "conservation_status": "Unknown",
      "marine": false,
      "habitat": "Unknown",
      "geographic_range": "Unknown",
      "behavior": "Unknown",
      "diet": "Unknown"
    };
  }

  Future<Map<String, dynamic>> _parseJson(String jsonString) async {
    try {
      return await compute(_parseJsonIsolate, jsonString)
          .timeout(const Duration(seconds: 2), onTimeout: () {
        throw TimeoutException('JSON parsing timed out');
      });
    } catch (e) {
      final cleanedString = jsonString
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      try {
        return await compute(_parseJsonIsolate, cleanedString)
            .timeout(const Duration(seconds: 2), onTimeout: () {
          throw TimeoutException('JSON parsing timed out');
        });
      } catch (e) {
        return _getDefaultResponse();
      }
    }
  }
}

Map<String, dynamic> _parseJsonIsolate(String jsonString) {
  try {
    return json.decode(jsonString) as Map<String, dynamic>;
  } catch (e) {
    final jsonRegExp = RegExp(r'{[\s\S]*}');
    final match = jsonRegExp.firstMatch(jsonString);
    if (match != null) {
      final jsonStr = match.group(0);
      if (jsonStr != null) {
        return json.decode(jsonStr) as Map<String, dynamic>;
      }
    }
    throw e;
  }
}

Uint8List _encodePngIsolate(img.Image image) {
  return img.encodePng(image);
}

int min(int a, int b) {
  return a < b ? a : b;
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);

  @override
  String toString() => 'TimeoutException: $message';
}
