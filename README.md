# Paper Trade App

A beautiful Flutter app for paper trading stocks with AI-powered trading signals and real-time data from Yahoo Finance.

## Features

- 📈 **Live Stock Data**: Real-time quotes from Yahoo Finance API
- 🤖 **AI Trading Signals**: Get buy/sell recommendations powered by OpenRouter AI
- 💼 **Paper Trading**: Virtual portfolio with $100,000 starting balance
- 📊 **Interactive Charts**: Beautiful price charts using fl_chart
- 🌙 **Dark Theme**: Premium Upstox-inspired UI design
- 🔄 **Auto-Refresh**: Watchlist updates every 10 minutes on weekdays

## Setup

### 1. Install Dependencies

```bash
flutter pub get
```

### 2. Configure OpenRouter API Key

To use AI trading signals, you need an OpenRouter API key:

1. Get a free API key from [OpenRouter](https://openrouter.ai/)
2. Open `lib/main.dart`
3. Replace `'YOUR_OPENROUTER_API_KEY'` with your actual API key:

```dart
ChangeNotifierProvider(
  create: (_) => AIProvider(
    apiKey: 'sk-or-v1-...', // Your API key here
    model: 'z-ai/glm-4.5-air:free',
  ),
),
```

### 3. Run the App

```bash
flutter run
```

## How to Use

1. **Watchlist**: View your saved stocks. The list auto-refreshes every 10 minutes during weekdays.
2. **Search**: Tap the '+' button to search and add stocks.
3. **Stock Details**: Tap any stock to view charts and detailed information.
4. **Trading**: 
   - On the stock detail screen, tap BUY or SELL
   - The app will analyze the stock with AI and show a signal (BUY/SELL/HOLD) with confidence
   - Enter quantity and confirm your trade
5. **Portfolio**: View your holdings and available cash.
6. **Orders**: See your trade history.

## AI Trading Signals

When you open a buy/sell trade sheet, the app automatically:
- Fetches 30 days of historical price data
- Sends it to OpenRouter AI for analysis
- Displays the AI's recommendation with confidence level
- Shows reasoning for the signal

You can still execute trades that go against the AI signal - it's just a recommendation!

## Live Watchlist

- Automatically refreshes every 10 minutes
- Only updates Mon-Fri (market days)
- Shows last update time in the header
- Tap refresh icon to manually update

## Technologies

- **Flutter**: Cross-platform UI framework
- **Provider**: State management
- **fl_chart**: Interactive charts
- **Yahoo Finance API**: Stock data
- **OpenRouter**: AI analysis
- **Google Fonts**: Typography

## License

MIT
