# Paper Trade App

A Flutter-based paper trading application with AI-powered analysis, supporting multiple platforms.

## ✨ Features

- 📊 Real-time stock watchlist with Yahoo Finance data
- 💼 Virtual portfolio management (₹100,000 starting capital)
- 🤖 AI-powered trading analysis (OpenRouter integration)
- 📈 Technical indicators (PSAR, RSI, MACD, Bollinger Bands)
- 📱 Cross-platform (Android, Web, Linux desktop)
- 🔐 Google Sign-In with Firebase (Android/Web)
- 💾 Hybrid storage (Cloud sync on Android/Web, local on Linux/Windows)

## 🚀 Quick Start

### For Contributors

See [SETUP.md](SETUP.md) for detailed setup instructions.

**Quick setup:**
```bash
# Clone and install dependencies
git clone <your-repo-url>
cd paper_trade_app
flutter pub get

# Copy example config files
cp lib/config/firebase_options.dart.example lib/config/firebase_options.dart
cp android/app/google-services.json.example android/app/google-services.json
cp .env.example .env

# Edit the files above with your Firebase credentials
# Then run the app
flutter run
```

## 📱 Platform Support

| Platform | Google Sign-In | Cloud Sync | Local Storage |
|----------|---------------|------------|---------------|
| Android  | ✅            | ✅         | ✅            |
| Web      | ✅            | ✅         | ✅            |
| Linux    | ❌            | ❌         | ✅            |
| Windows  | ❌            | ❌         | ✅            |

## 🔧 Configuration Required

1. **Firebase Project**: For authentication and cloud storage
2. **OpenRouter API Key**: For AI analysis features (optional)

See [SETUP.md](SETUP.md) for detailed configuration steps.

## 📖 Documentation

- [Setup Guide](SETUP.md) - Complete setup instructions
- [Firebase Setup](https://console.firebase.google.com/) - Firebase console
- [OpenRouter](https://openrouter.ai/) - AI API provider

## ⚠️ Disclaimer

This is a paper trading application for educational purposes only. Virtual money is used for trading simulations. Not intended for real financial advice or actual trading.
