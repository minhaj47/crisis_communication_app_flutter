# Ummah Connect - Crisis Communication App

Ummah Connect is a Flutter-based mobile application designed for crisis communication, leveraging mesh networking technology to enable communication in environments with limited or no internet connectivity. The app is built with a focus on providing essential tools for users to stay connected and safe during emergencies.

## Features

- **Mesh Networking:** Utilizes the Bridgefy SDK to create a mesh network, allowing users to communicate with each other without an internet connection.
- **Broadcast Messaging:** Users can send broadcast messages to all other users on the network, enabling mass communication during a crisis.
- **Role-Based Access:** The app supports different user roles, such as "Citizen" and "First Responder," to provide tailored features and access levels.
- **SOS Alerts:** A dedicated SOS screen allows users to send distress signals to nearby users.
- **Flashlight Utility:** Includes a built-in flashlight feature for use in low-light conditions.
- **Location Sharing:** Users can share their location with others on the network, which is displayed on an integrated map.
- **Settings:** A settings screen allows users to configure their profile and app preferences.

## Technologies Used

- **Flutter:** The UI toolkit for building natively compiled applications for mobile, web, and desktop from a single codebase.
- **Bridgefy SDK:** Enables mesh networking capabilities for offline communication.
- **Provider:** For state management.
- **Flutter Map:** For displaying maps and user locations.
- **Geolocator:** To get the device's location.
- **Permission Handler:** To handle app permissions for location, Bluetooth, and other services.
- **Other packages:** `torch_light`, `uuid`, `connectivity_plus`, `shared_preferences`, `package_info_plus`, `http`, `vibration`, `flutter_ringtone_player`, `wakelock_plus`, `audioplayers`, `latlong2`, and `url_launcher`.

## Getting Started

To get a local copy up and running, follow these simple steps.

### Prerequisites

- Flutter SDK: [https://flutter.dev/docs/get-started/install](https://flutter.dev/docs/get-started/install)
- An editor like Android Studio or VS Code with the Flutter plugin.

### Installation

1. Clone the repo:
   ```sh
   git clone https://github.com/your_username/crisis_communication_app_flutter.git
   ```
2. Navigate to the project directory:
   ```sh
   cd crisis_communication_app_flutter
   ```
3. Install packages:
   ```sh
   flutter pub get
   ```
4. Run the app:
   ```sh
   flutter run
   ```

## Project Structure

The project is structured as follows:

- `lib/`
  - `main.dart`: The entry point of the application.
  - `screens/`: Contains the UI for each screen of the app.
  - `widgets/`: Contains reusable widgets used across multiple screens.
  - `providers/`: Contains the providers for state management.
  - `services/`: Contains the services for interacting with the Bridgefy SDK and other platform-specific features.
  - `models/`: Contains the data models for the app.
  - `utils/`: Contains utility functions and constants.
