# ⚡ Quick Reference

## File Locations

| File | Purpose |
|------|---------|
| `src/index.jsx` | App entry point |
| `src/App.jsx` | Root component |
| `src/components/Phone.jsx` | Main phone container |
| `src/components/screens/` | HomeScreen, LockScreen, CallScreen |
| `src/components/apps/` | Individual app components |
| `src/utils/nui.js` | NUI communication |
| `src/hooks/` | React custom hooks |
| `src/styles/` | CSS styling |
| `package.json` | Dependencies & scripts |
| `vite.config.js` | Build config |

## Commands

```bash
# Setup
npm install

# Development
npm run dev              # Start dev server

# Production
npm run build            # Build for production
npm run preview          # Preview production build
```

## Key Files to Understand

1. **src/index.jsx** - React root, mounts App
2. **src/App.jsx** - Listens to NUI events, renders Phone
3. **src/components/Phone.jsx** - Phone frame with screens
4. **src/utils/nui.js** - NUI communication functions
5. **package.json** - Project dependencies

## Component Hierarchy

```
App
├── Phone
│   ├── LockScreen
│   ├── HomeScreen
│   │   ├── StatusBar
│   │   ├── AppGrid
│   │   │   └── [App Icons]
│   │   └── Notifications
│   └── CallScreen
├── PhoneApp
├── MessagesApp
├── SettingsApp
├── CameraApp
├── NotesApp
└── CalculatorApp
```

## NUI Events

```javascript
// From UI to Server
fetchNui('eventName', { data })

// From Server to UI
onNuiEvent('eventName', (data) => {})
```

## Development Tips

1. **Hot Reload** - Changes auto-refresh in dev mode
2. **DevTools** - Press F12 in browser
3. **Console** - Check browser console for errors
4. **Network** - View NUI calls in Network tab
5. **Elements** - Inspect DOM in Elements tab

## Common Tasks

### Add New App
1. Create `src/components/apps/YourApp.jsx`
2. Import in phone.jsx
3. Add to AppGrid

### Add New Screen
1. Create `src/components/screens/YourScreen.jsx`
2. Import in Phone.jsx
3. Add state logic

### Modify Styling
1. Edit `src/styles/` files
2. Or add CSS in component files
3. Changes auto-refresh

## Troubleshooting

| Issue | Solution |
|-------|----------|
| npm install fails | Delete `node_modules` and `package-lock.json`, reinstall |
| Dev server not starting | Check if port 3000 is available |
| NUI not working | Verify script name and event listeners |
| Styles not applied | Check CSS imports and selector specificity |
| Hot reload not working | Restart dev server |

## Build Output

After `npm run build`:
- `dist/` folder created
- `dist/index.html` - HTML entry
- `dist/assets/` - JS, CSS, images
- Ready to deploy to FiveM resource

## Documentation Files

- `README.md` - Project overview
- `RECOVERY_GUIDE.md` - Complete guide
- `RECOVERY_COMPLETE.md` - Summary
- This file - Quick reference

## Links

- [React Docs](https://react.dev)
- [Vite Docs](https://vitejs.dev)
- [Framer Motion](https://www.framer.com/motion/)
- [FiveM NUI](https://docs.fivem.net/docs/scripting-reference/nui-development/)

---

**All 100% of original UI code has been successfully recovered! 🎉**
