# Release Notes - v1.0.0

## 🎉 First Release - Paper Trade App

A cross-platform paper trading application with AI-powered analysis.

### ✨ Features

- **Virtual Trading**
  - ₹100,000 starting capital
  - Real-time stock prices (Yahoo Finance)
  - Buy/Sell order execution
  - Portfolio tracking with live P&L

- **AI-Powered Analysis** 
  - OpenRouter integration for stock analysis
  - Technical indicators (PSAR, RSI, MACD, Bollinger Bands)
  - Automated trading recommendations
  - Daily portfolio scanning

- **Multi-Platform Support**
  - Android (Google Sign-In + Firebase)
  - Linux Desktop (local storage)
  - *(Web support coming soon)*

- **User Management**
  - Google Sign-In authentication
  - Cloud sync for portfolio data (Android)
  - Local storage fallback (Linux/Desktop)

### 📱 Installation

#### Android APK
Download and install `app-release.apk` from the assets below.

**Requirements:**
- Android 5.0 (API 21) or higher
- Google Play Services (for sign-in)

**First Launch:**
1. Install the APK
2. Sign in with your Google account
3. Start trading!

### 🔧 Setup for Developers

See [SETUP.md](https://github.com/abhishekpeddada/paper-trade-app/blob/main/SETUP.md) for detailed instructions.

**Quick start:**
```bash
git clone https://github.com/abhishekpeddada/paper-trade-app.git
cd paper_trade_app
flutter pub get
# Configure Firebase (see SETUP.md)
flutter run
```

### 📝 Known Limitations

- Web build has dependency conflicts (being resolved)
- iOS not yet supported (requires Firebase iOS configuration)
- Google Sign-In only available on Android/Web (Linux uses local storage)

### 🐛 Bug Reports

Please report issues at: https://github.com/abhishekpeddada/paper-trade-app/issues

### 📄 License

See LICENSE file for details.

---

**Full Changelog**: Initial release

**APK Size**: 53MB
**Build**: Release
**Flutter Version**: 3.38.3
