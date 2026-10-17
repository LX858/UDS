# LB Phone UI

A React-based phone interface for FiveM LB Phone resource.

## Project Structure

```
src/
├── components/
│   ├── screens/          # Main screen components
│   │   ├── HomeScreen.jsx
│   │   ├── LockScreen.jsx
│   │   └── CallScreen.jsx
│   ├── AppGrid.jsx       # App grid component
│   ├── StatusBar.jsx     # Top status bar
│   ├── Notification.jsx  # Notification component
│   └── Phone.jsx         # Main phone component
├── hooks/                # Custom React hooks
│   ├── useNuiEvent.js
│   └── useFetchNui.js
├── utils/                # Utility functions
│   └── nui.js           # NUI communication
├── styles/               # Global styles
│   ├── index.css
│   ├── phone.css
│   ├── app-grid.css
│   └── status-bar.css
├── App.jsx              # Root App component
├── App.css
└── index.jsx            # React entry point
```

## Setup

1. Install dependencies:
```bash
npm install
```

2. Start development server:
```bash
npm run dev
```

3. Build for production:
```bash
npm run build
```

## Features

- Responsive phone UI
- Lock screen with time display
- Home screen with app grid
- Call screen interface
- Status bar with signal and battery
- Real-time notifications
- FiveM NUI integration

## Configuration

Edit configuration files:
- `vite.config.js` - Build configuration
- `package.json` - Project metadata and dependencies

## NUI Communication

Use the provided utilities in `src/utils/nui.js`:

```javascript
import { fetchNui, onNuiEvent } from './utils/nui';

// Fetch data from server
const data = await fetchNui('eventName', { param: 'value' });

// Listen for events from server
onNuiEvent('eventName', (data) => {
  console.log('Received:', data);
});
```

## Custom Hooks

Use custom hooks for NUI integration:

```javascript
import { useNuiEvent } from './hooks/useNuiEvent';
import { useFetchNui } from './hooks/useFetchNui';

// Listen to NUI events
useNuiEvent('eventName', (data) => {
  // Handle event
});

// Fetch NUI data with loading state
const { execute, loading, error } = useFetchNui();
```

## Styling

Styles are organized in `src/styles/`:
- `index.css` - Global styles
- `phone.css` - Phone frame and screen styles
- `app-grid.css` - App grid styles
- `status-bar.css` - Status bar styles

## License

All rights reserved.
