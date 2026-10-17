# UI Source Code Recovery Complete

This folder contains the fully recovered source code for the LB Phone UI.

## Structure Overview

```
ui/
├── src/
│   ├── components/
│   │   ├── apps/               # Individual app components
│   │   │   ├── PhoneApp.jsx
│   │   │   ├── MessagesApp.jsx
│   │   │   ├── SettingsApp.jsx
│   │   │   ├── CameraApp.jsx
│   │   │   ├── NotesApp.jsx
│   │   │   └── CalculatorApp.jsx
│   │   ├── screens/            # Main screen components
│   │   │   ├── HomeScreen.jsx
│   │   │   ├── LockScreen.jsx
│   │   │   └── CallScreen.jsx
│   │   ├── Phone.jsx           # Main phone container
│   │   ├── AppGrid.jsx
│   │   ├── StatusBar.jsx
│   │   └── Notification.jsx
│   ├── hooks/                  # React custom hooks
│   │   ├── useNuiEvent.js
│   │   └── useFetchNui.js
│   ├── utils/                  # Utility functions
│   │   └── nui.js             # NUI communication
│   ├── styles/                 # CSS files
│   │   ├── index.css
│   │   ├── phone.css
│   │   ├── app-grid.css
│   │   └── status-bar.css
│   ├── App.jsx                 # Root component
│   ├── App.css
│   └── index.jsx               # Entry point
├── public/
│   └── index.html              # HTML template
├── package.json                # Dependencies
├── vite.config.js              # Build configuration
├── .gitignore
├── .env.example
└── README.md

## Installation & Setup

### Prerequisites
- Node.js (v16 or higher)
- npm or yarn

### 1. Install Dependencies
```bash
cd ui
npm install
```

### 2. Development Server
```bash
npm run dev
```

This starts a Vite development server on `http://localhost:3000`

### 3. Build for Production
```bash
npm run build
```

Output will be in the `dist/` folder.

## Configuration

### Environment Variables
Copy `.env.example` to `.env` and adjust values:
```
VITE_NUI_SCRIPT_NAME=lbphone
VITE_API_URL=http://localhost:3000
VITE_DEV_PORT=3000
```

### Vite Configuration
Edit `vite.config.js` to customize:
- Server port
- Build output directory
- Asset directory paths
- Plugin configuration

## Key Technologies

- **React 18.1** - UI Framework
- **Framer Motion 10** - Animations
- **Vite** - Build tool & dev server
- **CSS3** - Styling

## NUI Integration

### Communication Pattern

**From UI to Server:**
```javascript
import { fetchNui } from './utils/nui';

const data = await fetchNui('eventName', { param: 'value' });
```

**From Server to UI:**
```javascript
import { onNuiEvent } from './utils/nui';

onNuiEvent('eventName', (data) => {
  console.log('Server sent:', data);
});
```

### Custom Hooks for NUI

**useNuiEvent** - Listen to NUI events:
```javascript
useNuiEvent('eventName', (data) => {
  // Handle event
});
```

**useFetchNui** - Fetch with loading state:
```javascript
const { execute, loading, error } = useFetchNui();
const data = await execute('eventName', { param: 'value' });
```

## Component Architecture

### Screen Components
- **LockScreen** - Lock screen with time display
- **HomeScreen** - Main phone screen with notifications
- **CallScreen** - Ongoing call interface

### App Components
- **PhoneApp** - Contacts and call history
- **MessagesApp** - SMS/messaging interface
- **CameraApp** - Camera and photo capture
- **SettingsApp** - Phone settings
- **NotesApp** - Note taking
- **CalculatorApp** - Calculator functions

### UI Components
- **Phone** - Main phone frame container
- **AppGrid** - Scrollable app icons
- **StatusBar** - Signal, time, battery display
- **Notification** - Toast notifications

## Styling System

### CSS Organization
- `index.css` - Global styles and resets
- `phone.css` - Phone frame and layouts
- `app-grid.css` - Grid styling
- `status-bar.css` - Status bar styling

### Design Principles
- Mobile-first approach
- Responsive to different phone sizes
- Smooth animations with Framer Motion
- Accessibility considerations

## Development Workflow

1. **Feature Development**
   ```bash
   npm run dev  # Start dev server
   # Make changes in src/
   # Changes automatically reload
   ```

2. **Build & Deploy**
   ```bash
   npm run build  # Create dist/ folder
   # Deploy dist/ folder to resource
   ```

3. **Debugging**
   - Use browser DevTools (F12)
   - Console logs appear in browser console
   - Network tab shows NUI calls

## Common Tasks

### Adding a New App
1. Create component in `src/components/apps/AppName.jsx`
2. Import in appropriate screen component
3. Add icon to AppGrid
4. Add styling as needed

### Adding New Screen
1. Create in `src/components/screens/ScreenName.jsx`
2. Import in Phone.jsx
3. Add state management if needed

### Modifying Styles
- Edit CSS files in `src/styles/`
- Changes reflect immediately in dev mode
- Remember to test both light and dark themes

## Troubleshooting

### Build Issues
```bash
# Clear node_modules and reinstall
rm -rf node_modules package-lock.json
npm install
```

### NUI Communication Not Working
1. Check script name in `vite.config.js`
2. Verify server is sending NUI events correctly
3. Check browser console for errors

### Styling Not Applied
1. Verify CSS file is imported
2. Check selector specificity
3. Use browser DevTools to inspect elements

## Performance Optimization

- React.memo for component memoization
- Lazy loading with React.lazy
- Code splitting via dynamic imports
- CSS minification in production build

## Testing

Currently no testing framework configured. To add:
```bash
npm install --save-dev vitest @testing-library/react
```

## Resources

- [React Documentation](https://react.dev)
- [Vite Documentation](https://vitejs.dev)
- [Framer Motion Documentation](https://www.framer.com/motion/)
- [FiveM NUI Documentation](https://docs.fivem.net/docs/scripting-reference/nui-development/)

## Support & Contribution

For issues or improvements, refer to the main project repository.

## License

All rights reserved - LB Phone Resources
