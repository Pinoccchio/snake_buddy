# Snake Buddy
A mobile snake identificator.

---

## ⚙️ API Key Configuration

**IMPORTANT:** To use the snake identification feature, you must provide your own Google Generative AI API key. The application will not work without it.

It is highly recommended to use a `.env` file to manage your API key securely. You can do this by:

1.  Creating a file named `.env` in the root of your project.
2.  Adding your API key to the `.env` file:
    ```
    GEMINI_API_KEY=YOUR_API_KEY_HERE
    ```
3.  Adding `.env` to your `.gitignore` file to prevent it from being committed to version control.
4.  Ensuring the application is configured to load this key at runtime. I can help you implement this.

---

## Getting Started

To run this project, you will need to have the Flutter SDK installed.

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/your-username/snake_buddy.git
    cd snake_buddy
    ```

2.  **Install dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Configure your API Key:**
    Follow the instructions in the "API Key Configuration" section to add your Gemini API key to a `.env` file.

4.  **Run the app:**
    ```bash
    flutter run
    ```

## Project Structure