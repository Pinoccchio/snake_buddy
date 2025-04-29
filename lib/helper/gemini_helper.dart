import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image/image.dart' as img;

class GeminiHelper {
  // Replace with your actual API key
  static const String _apiKey = "AIzaSyDwnVkCEvCL9VtPxy84tQ3QrU3QhiUH3oM";
  static const String _modelName = 'gemini-1.5-pro';

  Future<Map<String, dynamic>> analyzeSnakeImage(img.Image image) async {
    try {
      // Initialize the Gemini model
      final model = GenerativeModel(
        model: _modelName,
        apiKey: _apiKey,
      );

      // Convert the image to bytes
      final bytes = img.encodePng(image);

      // Create a prompt for snake identification
      final prompt = '''
You are a snake identification expert specializing in Philippine snakes. Analyze this image and identify the snake species shown.

Focus specifically on these Philippine snake species:
1. Albino Burmese Python (Python bivittatus)
2. Asian Sunbeam Snake (Xenopeltis unicolor)
3. Banded Malaysian (Lycodon subcinctus)
4. Blue-Lipped Sea Krait (Laticauda laticaudata)
5. Blunthead Slug Snake (Aplopeltura boa)
6. Chinese Sea Krait (Laticauda semifasciata)
7. Common Mock Viper (Psammodynastes pulverulentus)
8. Coral Snake (Calliophis spp.)
9. Dog-Toothed Cat Snake (Boiga cynodon)
10. Gold-Ringed Cat Snake (Boiga dendrophila)
11. Green Tree Python (Morelia viridis)
12. King Cobra (Ophiophagus hannah)
13. Marine File Snake (Acrochordus granulatus)
14. Oriental Whipsnake (Ahaetulla prasina)
15. Ornate Sea Snake (Hydrophis ornatus)
16. Painted Bronzeback (Dendrelaphis pictus)
17. Paradise Flying Snake (Chrysopelea paradisi)
18. Philippine Pit Viper (Trimeresurus flavomaculatus)
19. Philippine Shrub Snake (Gongylosoma semperi)
20. Red-Tailed Green Ratsnake (Gonyosoma oxycephalum)
21. Reticulated Python (Python reticulatus)
22. Samar Cobra (Naja samarensis)
23. Specklebelly Keelback (Rhabdophis chrysargos)
24. Yellow-Bellied Sea Snake (Hydrophis platurus)

If the image does not clearly show one of these Philippine snake species, respond with "Random" as the name.

Provide the following information in your analysis:
1. Common name of the snake (or "Random" if not identifiable as one of the listed species)
2. Scientific name (genus and species)
3. Whether it is venomous (true/false)
4. Physical description including size, color patterns, and distinct features
5. Conservation status (e.g., Least Concern, Vulnerable, Endangered)
6. Whether it is aquatic/marine (true/false)
7. Habitat information and geographic distribution
8. Behavior characteristics and diet
9. Any notable facts or interesting information about the species

Format your response ONLY as a valid JSON object with these properties:
{
  "name": "Common Name",
  "scientific_name": "Genus species",
  "venomous": true/false,
  "description": "Detailed description of the snake",
  "classification": {
    "size": "Size description (e.g., Small, Medium, Large)",
    "color_pattern": "Description of coloration and patterns",
    "distinct_feature": "Notable identifying features"
  },
  "conservation_status": "Conservation status",
  "marine": true/false,
  "habitat": "Typical habitat information",
  "geographic_range": "Geographic distribution",
  "behavior": "Behavioral characteristics",
  "diet": "Feeding habits and prey"
}

If the snake is not identifiable as one of the listed Philippine species, use "Random" as the name and provide general information about snakes.
''';

      // Create content parts with the image and prompt
      final imagePart = DataPart('image/png', bytes);
      final textPart = TextPart(prompt);
      final content = [Content.multi([textPart, imagePart])];

      // Generate content
      final response = await model.generateContent(content);
      final responseText = response.text ?? '';

      debugPrint('Raw response: $responseText');

      // Parse the JSON response
      try {
        // Extract JSON from the response text
        final jsonRegExp = RegExp(r'{[\s\S]*}');
        final match = jsonRegExp.firstMatch(responseText);

        if (match != null) {
          final jsonStr = match.group(0);
          if (jsonStr != null) {
            return Map<String, dynamic>.from(await _parseJson(jsonStr));
          }
        }

        // If we couldn't extract JSON using regex, try direct parsing
        return Map<String, dynamic>.from(await _parseJson(responseText));

      } catch (e) {
        debugPrint('Error parsing JSON: $e');
        debugPrint('Response text: $responseText');

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
    } catch (e) {
      debugPrint('Error in analyzeSnakeImage: $e');
      return {
        'error': true,
        'message': 'Error analyzing image',
        'details': e.toString()
      };
    }
  }

  Future<Map<String, dynamic>> _parseJson(String jsonString) async {
    try {
      // Try to parse directly
      return await compute(_parseJsonIsolate, jsonString);
    } catch (e) {
      // If that fails, try to clean up the string
      final cleanedString = jsonString
          .replaceAll('```json', '')  // Remove markdown code markers
          .replaceAll('```', '')      // Remove closing markdown marker
          .trim();                   // Trim whitespace

      return await compute(_parseJsonIsolate, cleanedString);
    }
  }
}

// Helper for JSON parsing in isolate
Map<String, dynamic> _parseJsonIsolate(String jsonString) {
  return json.decode(jsonString) as Map<String, dynamic>;
}

// Compute function to run in isolate
Future<Map<String, dynamic>> compute(
    Function(String) callback, String message) async {
  final port = ReceivePort();
  await Isolate.spawn((Map<String, dynamic> map) {
    final sendPort = map['port'] as SendPort;
    final message = map['message'] as String;
    final callback = map['callback'] as Function(String);

    try {
      final result = callback(message);
      sendPort.send({'result': result});
    } catch (e) {
      sendPort.send({'error': e.toString()});
    }

  }, {
    'port': port.sendPort,
    'message': message,
    'callback': callback,
  });

  final result = await port.first as Map<String, dynamic>;
  port.close();

  if (result.containsKey('error')) {
    throw Exception(result['error']);
  }
  return result['result'];
}
