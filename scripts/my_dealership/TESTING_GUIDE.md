# Quick Testing Guide - Dealership UI

## How to Test Category Filtering

### 1. Test in Browser (Immediate)

1. Open this file in Chrome:
   ```
   /my_dealership/html/index.html
   ```

2. Open Developer Console (F12)

3. You should see:
   - Dealership UI opens after 1 second
   - Category tabs: `[All (13)] [Compacts (6)] [Sports (3)] [Super (4)]`
   - "All" tab is active (green border)
   - 13 vehicles in list
   - Panel label: "AVAILABLE VEHICLES (13)"

4. Click "Compacts" tab:
   - Tab turns green
   - List shows only 6 Compacts vehicles
   - Panel label: "AVAILABLE VEHICLES (6)"
   - First vehicle auto-selected

5. Click "Sports" tab:
   - List shows only 3 Sports vehicles
   - Panel label: "AVAILABLE VEHICLES (3)"

6. Click "Super" tab:
   - List shows only 4 Super vehicles
   - Panel label: "AVAILABLE VEHICLES (4)"

7. Click "All" tab:
   - Back to full list (13 vehicles)
   - Panel label: "AVAILABLE VEHICLES (13)"

### 2. Test in FiveM (After Resource Restart)

1. **Restart the resource:**
   ```
   restart my_dealership
   ```

2. **Open dealership in-game** (use your command/trigger)

3. **Check F8 Console** for logs:
   ```
   [Dealership] Loading image: images/rhapsody.jpg
   [Dealership] Image failed to load: images/rhapsody.jpg
   [Dealership] Full path would be: nui://my_dealership/html/images/rhapsody.jpg
   ```

4. **Test category filtering:**
   - Click each category tab
   - Verify vehicle list filters correctly
   - Check panel label updates with count
   - Ensure first vehicle auto-selects

### 3. Fix Image Issue

**Why images don't show:**
- The `/html/images/` folder is empty (only has README.txt)

**How to fix:**

1. **Add image files** to:
   ```
   /my_dealership/html/images/
   ```

2. **Naming convention:**
   - File name must match vehicle model from config.lua
   - Format: `{model}.jpg`
   - Examples:
     - `rhapsody.jpg`
     - `prairie.jpg`
     - `adder.jpg`
     - `t20.jpg`

3. **Where to get images:**
   - GTA Wiki vehicle pages
   - Screenshot from game
   - Google: "gta 5 {vehicle name} side view"
   - Use landscape photos (16:9 ratio)

4. **Resize images (recommended):**
   - Resolution: 800x450px
   - Format: JPG
   - Compress to < 200KB each
   - Use tools: Photoshop, GIMP, or online compressor

5. **After adding images:**
   - Restart resource: `restart my_dealership`
   - Images should now load
   - Check F8 console for success: `[Dealership] Image loaded successfully: images/rhapsody.jpg`

---

## What You Should See

### ✅ Working Features
- Category tabs appear between header and vehicle list
- Tabs show category name and count: `Compacts (6)`
- Active tab has green border and glow
- Clicking tab filters vehicle list
- Panel label updates: `AVAILABLE VEHICLES (X)`
- First vehicle auto-selected when filtering
- Smooth animations and transitions

### ⚠️ Known Issues
- **Images show placeholder:** This is EXPECTED (folder is empty)
- **Fix:** Add JPG files to `/html/images/`

### 🔧 If Something Doesn't Work

**Category tabs don't appear:**
- Clear browser cache (Ctrl+Shift+Delete)
- Hard reload (Ctrl+F5)
- Check browser console for JavaScript errors

**Filtering doesn't work:**
- Make sure vehicles in config.lua have `category` field
- Check browser console for errors
- Verify category names match exactly (case-sensitive)

**In-game UI doesn't show:**
- Restart resource: `restart my_dealership`
- Check server console for errors (red text)
- Verify fxmanifest.lua hasn't been changed

---

## Console Commands for Testing

### In Browser Console (F12)
```javascript
// Test purchase success
testPurchaseSuccess()

// Test purchase failure
testPurchaseFailure()

// Check current state
console.log('Active Category:', activeCategory)
console.log('Filtered Vehicles:', filteredVehicles)
console.log('Category Data:', categoryData)
```

### In FiveM Console (F8)
- Look for green `[Dealership]` logs
- Red errors mean something failed
- Image paths will be logged

---

## Expected Console Output

### When UI Opens:
```
[Dealership] Running in browser mode - debug enabled
[Dealership] Loading image: images/rhapsody.jpg
[Dealership] Image failed to load: images/rhapsody.jpg
[Dealership] Full path would be: nui://my_dealership/html/images/rhapsody.jpg
```

### When Clicking Category:
```
(No console output - silent filtering)
```

### When Images Load (after adding files):
```
[Dealership] Loading image: images/rhapsody.jpg
[Dealership] Image loaded successfully: images/rhapsody.jpg
```

---

## Checklist

### Browser Testing
- [ ] UI opens automatically after 1 second
- [ ] Category tabs visible
- [ ] "All (13)" tab active by default
- [ ] Click "Compacts" → shows 6 vehicles
- [ ] Click "Sports" → shows 3 vehicles
- [ ] Click "Super" → shows 4 vehicles
- [ ] Panel label updates with counts
- [ ] First vehicle auto-selected
- [ ] Active tab has green border
- [ ] Hover effect on inactive tabs
- [ ] Image placeholders show

### FiveM Testing
- [ ] Resource restarts without errors
- [ ] UI opens in-game
- [ ] Categories detected from config.lua
- [ ] Filtering works with server data
- [ ] Purchase button works
- [ ] ESC key closes UI
- [ ] Images show (after adding files)

### Image Files
- [ ] JPG files added to `/html/images/`
- [ ] File names match vehicle models
- [ ] Images load in-game
- [ ] No console errors for images

---

**If everything works:** ✅ Implementation successful!  
**If issues:** Check F8/F12 console for error messages  
**Need help:** Share console errors with developer
