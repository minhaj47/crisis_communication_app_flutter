# Ummah Connect - Crisis Communication App

[![Flutter](https://img.shields.io/badge/Flutter-Framework-blue)](https://flutter.dev)
[![Mesh Networking](https://img.shields.io/badge/Mesh-Networking-green)](https://bridgefy.me)
[![Hackathon Project](https://img.shields.io/badge/Hackathon-Project-orange)]()

**Presented by NoSignalLab**

A Flutter-based mobile application engineered for crisis communication using mesh networking technology. Born from the need to provide reliable communication during emergencies when traditional infrastructure fails - inspired by real-world events like the Hong Kong Umbrella Movement, Iraq Protests, and various crisis situations worldwide.

## 🎯 Problem Statement

**What happens when the oppressed stand against oppressor?**

During crisis situations like natural disasters, protests, or conflicts, traditional communication infrastructure often fails or gets deliberately shut down. Historical events show the critical need for decentralized communication:

- **Hong Kong Umbrella Movement (2014)**: 100,000+ users needed alternative communication in 22 hours
- **Iraq Protests (2014)**: 40,000+ people sought mesh networking solutions
- **Various Global Crises**: From earthquakes to political unrest, people need reliable communication

## 📱 Screenshots

<div align="center">
  <img src="/chat_screen.png" alt="Chat Screen" width="190"/>
  <img src="/broadcast_messaging.png" alt="Broadcast Messaging" width="190"/>
  <img src="/sos_alert.png" alt="SOS Alert" width="190"/>
  <img src="/tools.png" alt="Tools" width="190"/>  
  <img src="/location_sharing.png" alt="Location Sharing" width="190"/>
</div>

## ✨ Key Features

### Communication Core
- **🌐 Mesh Networking**: Device-to-device communication without internet using Bluetooth and WiFi
- **📢 Broadcasting**: Mass communication to all network participants
- **💬 Individual & Group Chat**: Private and group messaging capabilities
- **📍 Location Sharing**: Real-time GPS position sharing with integrated maps

### Emergency Tools
- **🆘 SOS Alerts**: Dedicated distress signal system
- **🔦 Flashlight**: Built-in emergency lighting
- **🚨 Alert Tools**: Comprehensive emergency notification system
- **👤 User Profiles**: Role-based access and user management

### Technical Advantages
- **🔐 Encrypted Communication**: Secure message transmission
- **🔋 Super Power Saving Mode**: Extended battery life during emergencies
- **📱 Cross-Platform**: Available on Android and iOS
- **🌐 No Infrastructure Dependency**: Works without cellular towers or internet

## 🛠️ Technologies Used

### Core Framework
- **Flutter**: Cross-platform mobile development
- **Provider**: State management solution
- **SQLite**: Local data storage and handling

### Networking & Communication
- **Bridgefy SDK**: Primary mesh networking solution
- **Bluetooth**: Local device discovery and communication
- **WiFi Direct**: Extended range peer-to-peer connectivity

### Mapping & Location
- **Flutter Map**: Interactive map display
- **Geolocator**: GPS positioning services

### Utilities
- **Permission Handler**: System permission management
- **Torch Light**: Flashlight control
- **Various Support Packages**: UUID, connectivity, shared preferences, etc.

## 🚧 Development Challenges & Solutions

### Major Challenge: SDK Limitations
We evaluated multiple mesh networking solutions and faced significant challenges:

| SDK | Issues Faced |
|-----|-------------|
| **Bridgefy** | Proprietary, limited documentation updates |
| **Ditto** | Not all necessary features available |
| **Meshrabiya** | Bluetooth only, limited range |
| **Others** | Discontinued projects, unsolved GitHub issues |

### Our Solution Approach
- **Open Source Philosophy**: Community-driven development
- **No Extra Infrastructure**: Free-of-cost solution
- **Minimal Data Requirements**: Efficient local storage with Provider and SQLite
- **Available Tools**: Leveraging existing capabilities for both connectivity and features

## 🎮 Current Implementation

### Completed Screens
**Main Navigation:**
- Welcome Page
- Map Page with location sharing
- Broadcast messaging system
- Individual chat interface

**Emergency Features:**
- SOS alert system
- SOS broadcasting
- Alert tools dashboard
- User profile management

## 📁 Project Structure

```
ummah_connect/
├── lib/
│   ├── main.dart              # Application entry point
│   ├── screens/               # UI screens
│   │   ├── welcome_screen.dart
│   │   ├── map_screen.dart
│   │   ├── broadcast_screen.dart
│   │   ├── chat_screen.dart
│   │   ├── sos_screen.dart
│   │   └── profile_screen.dart
│   ├── providers/             # State management
│   ├── services/              # Bridgefy and platform services
│   ├── models/                # Data models
│   └── utils/                 # Helper functions
└── pubspec.yaml
```

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.0+
- Android Studio or VS Code with Flutter plugin
- Bridgefy SDK credentials

### Installation
1. **Clone the repository**
   ```bash
   git clone https://github.com/your_username/crisis_communication_app_flutter.git
   cd crisis_communication_app_flutter
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the application**
   ```bash
   flutter run
   ```

## 🔮 Future Roadmap

### Immediate Goals
- [ ] **Plug & Play Architecture**: Simplified deployment and setup
- [ ] **Enhanced Encryption**: Advanced security protocols
- [ ] **Custom SDK Development**: Building our own mesh networking solution

### Long-term Vision
- [ ] **Community-Driven Platform**: Open source ecosystem
- [ ] **Global Crisis Network**: Worldwide emergency communication infrastructure
- [ ] **Multi-Protocol Support**: Various mesh networking technologies

## 🌍 Impact & Vision

Ummah Connect aims to be a **free, open-source, community-driven** crisis communication platform that requires no additional infrastructure. By learning from historical events and current limitations in existing solutions, we're building a tool that can truly serve communities in their most critical moments.

## 🤝 Contributing

This is a hackathon project with potential for real-world impact. Contributions are welcome to help build a robust crisis communication solution for global communities.

## 📄 License

Open source project - details to be determined based on community feedback and development progression.

---

**NoSignalLab - Connecting communities when signals fail** 🌍

*Jajakallahu Khairan*
