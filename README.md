# SnakeBuddy

A Flutter-based mobile application that identifies snake species from images using Google's Gemini AI.

## Description

SnakeBuddy is a mobile tool for identifying snakes from photos. Users can either capture a new image with their camera or upload one from their gallery. The app sends the image to Google's Gemini 1.5 Pro model for a detailed analysis and returns comprehensive information about the snake.

## Features

- **AI-Powered Identification:** Leverages the Gemini 1.5 Pro vision model for accurate snake identification.
- **Camera and Gallery Support:** Analyze images taken in real-time or uploaded from your device.
- **Detailed Results Page:** Displays information including an overview, identification details, and safety advice.
- **Discover Section:** An offline-first catalog of snakes found in the Philippines.

---

## ⚙️ API Key Configuration

**IMPORTANT:** To use the snake identification feature, you must provide your own Google Generative AI API key.

1.  Create a file named `.env` in the root of your project.
2.  Add your API key to the `.env` file:
    ```
    GEMINI_API_KEY=YOUR_API_KEY_HERE
    ```
3.  Add `.env` to your [.gitignore](cci:7://file:///c:/Users/User/Documents/first_year_files/folder_for_jobs/SnakeBuddy/snake_buddy/.gitignore:0:0-0:0) file to prevent it from being committed to version control.
4.  The application is configured to load this key at runtime.

---

## Getting Started

1.  **Clone the repository.**
2.  **Install dependencies:** `flutter pub get`
3.  **Configure your API Key:** Follow the instructions above.
4.  **Run the app:** `flutter run`

## Project Structure

-   `lib/`: Contains all the Dart source code.
    -   [main.dart](cci:7://file:///c:/Users/User/Documents/first_year_files/folder_for_jobs/SnakeBuddy/snake_buddy/lib/main.dart:0:0-0:0): The main entry point.
    -   [helper/gemini_helper.dart](cci:7://file:///c:/Users/User/Documents/first_year_files/folder_for_jobs/SnakeBuddy/snake_buddy/lib/helper/gemini_helper.dart:0:0-0:0): Manages all communication with the Gemini API.
    -   [details.dart](cci:7://file:///c:/Users/User/Documents/first_year_files/folder_for_jobs/SnakeBuddy/snake_buddy/lib/details.dart:0:0-0:0): The screen that displays the analysis results.
    -   [discover.dart](cci:7://file:///c:/Users/User/Documents/first_year_files/folder_for_jobs/SnakeBuddy/snake_buddy/lib/discover.dart:0:0-0:0): The screen for browsing the snake catalog.
    -   [camera.dart](cci:7://file:///c:/Users/User/Documents/first_year_files/folder_for_jobs/SnakeBuddy/snake_buddy/lib/camera.dart:0:0-0:0): The page that handles camera functionality.
-   `assets/`: Contains static assets for the app (images, models, etc.).