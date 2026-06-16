# VISUAL TESTING REFERENCE
## Vehicle Dealership NUI - Quick Test Guide

---

## Expected Visual Appearance

### DESKTOP VIEW (900px max-width)

```
┌────────────────────────────────────────────────────────────────────────┐
│  VEHICLE DEALERSHIP                                              [✕]   │
├──────────────────────────────────┬─────────────────────────────────────┤
│  AVAILABLE VEHICLES              │                                     │
├──────────────────────────────────┤                                     │
│ ┌──────────────────────────────┐ │   Selected Vehicle                  │
│ │ Truffade Adder      $50,000  │ │   TRUFFADE ADDER                    │
│ │ Super                        │ │   ─────────────────────             │
│ └──────────────────────────────┘ │                                     │
│ ┌──────────────────────────────┐ │   Price                             │
│ │ Progen T20          $45,000  │ │   $50,000                           │
│ │ Super                        │ │                                     │
│ └──────────────────────────────┘ │   Category                          │
│ ┌──────────────────────────────┐ │   Super                             │
│ │ Pegassi Zentorno    $40,000  │ │   ─────────────────────             │
│ │ Super                        │ │                                     │
│ └──────────────────────────────┘ │                                     │
│ │ [scrollable]                 │ │   ┌───────────────────────────┐     │
│ ▼                                │   │  PURCHASE VEHICLE         │     │
│                                  │   └───────────────────────────┘     │
│ 55% width                        │   45% width                         │
└──────────────────────────────────┴─────────────────────────────────────┘

Background: rgba(0, 0, 0, 0.7) - TRANSPARENT
Selected Item: Green border (#00ff88)
Prices: Green text (#00ff88)
ALL Text: 2px 2px 4px rgba(0, 0, 0, 0.8) shadow
```

---

### MOBILE VIEW (< 768px)

```
┌──────────────────────────┐
│  VEHICLE DEALERSHIP [✕]  │
├──────────────────────────┤
│  AVAILABLE VEHICLES      │
├──────────────────────────┤
│ ┌──────────────────────┐ │
│ │ Adder       $50,000  │ │
│ │ Super                │ │
│ └──────────────────────┘ │
│ │ [scrollable]         │ │
│ ▼                        │
├──────────────────────────┤
│                          │
│   TRUFFADE ADDER         │
│   ──────────────         │
│   Price: $50,000         │
│   Category: Super        │
│   ──────────────         │
│   [PURCHASE VEHICLE]     │
│                          │
└──────────────────────────┘

Single column layout
Scrollable top panel (40vh)
Details panel below
```

---

## Color Verification

### Background Colors
- Main container: `rgba(0, 0, 0, 0.7)` - 70% transparent black
- Header: `rgba(0, 0, 0, 0.85)` - 85% transparent black
- Vehicle items: `rgba(255, 255, 255, 0.05)` - Very subtle white

### Text Colors
- Primary: `rgba(255, 255, 255, 0.95)` - Almost white
- Secondary: `rgba(255, 255, 255, 0.75)` - 75% white
- Tertiary: `rgba(255, 255, 255, 0.6)` - 60% white

### Accent Colors
- Green: `#00ff88` - Bright cyan-green (prices, selected items, purchase button)
- Red: `#ff4444` - Bright red (close button, errors)

### Shadows
- ALL text: `2px 2px 4px rgba(0, 0, 0, 0.8)` - Strong black shadow

---

## Interactive States to Test

### 1. Vehicle Items
```
NORMAL      → rgba(255, 255, 255, 0.05) background
HOVER       → rgba(255, 255, 255, 0.1) + green border + slide right 5px
SELECTED    → Green border + green glow + green vehicle name
```

### 2. Purchase Button
```
NORMAL      → #00ff88 background, black text, green glow
HOVER       → Slightly darker green + lift up 2px + bigger glow
LOADING     → Gray background, "PROCESSING...", pulsing animation
DISABLED    → Very light gray, no interaction
```

### 3. Close Button
```
NORMAL      → Red border, red text on dark red background
HOVER       → Solid red background, white text, scale up 1.05x
ACTIVE      → Scale down 0.95x
```

### 4. Feedback Messages
```
SUCCESS     → Green border + green text + green glow
            → Auto-hide after 3 seconds
            → Text: "✓ Purchase Successful!"

ERROR       → Red border + red text + red glow
            → Auto-hide after 5 seconds
            → Text: "✗ Insufficient funds" (or custom message)
```

---

## Animation Testing

### UI Open (0.3s)
```
From: opacity 0, scale 0.95
To:   opacity 1, scale 1.0
Easing: cubic-bezier(0.4, 0, 0.2, 1)
```

### UI Close (0.2s)
```
From: opacity 1, scale 1.0
To:   opacity 0, scale 0.95
Easing: cubic-bezier(0.4, 0, 0.2, 1)
```

### Feedback Slide In (0.3s)
```
From: translateX(-50%, -30px), opacity 0
To:   translateX(-50%, 0), opacity 1
```

### Feedback Slide Out (0.3s)
```
From: translateX(-50%, 0), opacity 1
To:   translateX(-50%, -30px), opacity 0
```

### Purchase Button Loading (1.5s infinite)
```
Pulse animation: opacity 0.6 → 1.0 → 0.6
```

---

## Functional Testing Steps

### Test 1: Basic Open/Close
1. Trigger UI open → Should fadeIn smoothly
2. First vehicle should be auto-selected (green border)
3. Details panel shows first vehicle info
4. Click X button → UI should fadeOut and close
5. **PASS IF:** Smooth animations, no flicker, transparent background visible

### Test 2: Vehicle Selection
1. Open UI
2. Click on second vehicle in list
3. **CHECK:** 
   - First vehicle loses green border
   - Second vehicle gains green border
   - Details panel updates immediately
   - Price and category update correctly
4. Hover over vehicles → Should slide right 5px with green border
5. **PASS IF:** Selection changes instantly, hover effects smooth

### Test 3: Purchase Flow - Success
1. Open UI, select vehicle
2. Click "PURCHASE VEHICLE" button
3. **CHECK:**
   - Button changes to "PROCESSING..."
   - Button becomes gray and pulsing
   - Cannot click button again (disabled)
4. Server responds with success
5. **CHECK:**
   - Green banner appears: "✓ Purchase Successful!"
   - Banner auto-hides after 3 seconds
   - UI closes 1 second after success
6. **PASS IF:** No double-clicks possible, smooth feedback

### Test 4: Purchase Flow - Failure
1. Open UI, select vehicle
2. Click "PURCHASE VEHICLE" button
3. Server responds with failure (e.g., "Insufficient funds")
4. **CHECK:**
   - Red banner appears: "✗ Insufficient funds"
   - Banner auto-hides after 5 seconds
   - Button resets to "PURCHASE VEHICLE"
   - Button becomes clickable again
   - UI stays open
6. **PASS IF:** Button properly resets, can retry purchase

### Test 5: Empty Vehicle List
1. Server sends empty vehicles array
2. UI should show "No vehicles available" in list panel
3. Details panel should show "Select a vehicle to view details"
4. Purchase button should not exist
5. **PASS IF:** No errors, graceful empty state

### Test 6: ESC Key
1. Open UI
2. Press ESC key
3. UI should close (if client.lua SetNuiFocus is configured)
4. **PASS IF:** Closes cleanly, no errors

### Test 7: Responsive Design
1. Open UI in browser
2. Resize window to 768px width
3. **CHECK:** Layout changes to single column
4. Resize to 480px
5. **CHECK:** Font sizes reduce, padding adjusts
6. **PASS IF:** No overflow, all content visible

### Test 8: Spam Clicking
1. Open UI, select vehicle
2. Rapidly click "PURCHASE VEHICLE" 10 times
3. **CHECK:** Only ONE purchase request sent
4. Button disabled during processing
5. **PASS IF:** No duplicate requests to server

### Test 9: Long Vehicle Names
1. Test with vehicle name > 30 characters
2. **CHECK:** Name doesn't overflow container
3. Text should truncate or wrap gracefully
4. **PASS IF:** No layout breaking

### Test 10: Scrolling
1. Open UI with 10+ vehicles
2. Scroll through vehicle list
3. **CHECK:** Custom scrollbar visible
4. Scrollbar thumb is visible and interactive
5. Selected vehicle stays highlighted when scrolling
6. **PASS IF:** Smooth scrolling, no performance issues

---

## Browser Debugging

### Open in Browser (Outside FiveM)
1. Navigate to `my_dealership/html/index.html`
2. Open browser console (F12)
3. UI will auto-open with test data after 1 second
4. Test interactions without FiveM server

### Console Commands
```javascript
// Simulate successful purchase
testPurchaseSuccess()

// Simulate failed purchase
testPurchaseFailure()

// Check current state
console.log('Selected:', selectedVehicle)
console.log('Vehicles:', currentVehicles)
console.log('Purchasing:', isPurchasing)
```

---

## In-Game Testing (FiveM)

### Setup
1. Start FiveM server
2. Ensure my_dealership resource is started
3. Join server as player
4. Approach dealership location

### Test Commands (if applicable)
```
/dealership  - Open dealership UI
```

### Console Debugging
```lua
-- Server console
restart my_dealership

-- Client F8 console (in-game)
-- Check for JavaScript errors
```

### Expected Behavior
1. UI appears centered on screen
2. Game world visible through transparent background
3. Can see vehicle list and details
4. Purchase integrates with my_money system
5. Vehicle spawns or is saved to player data

---

## Known Issues / Edge Cases

### ✓ Handled
- Empty vehicle list → Shows empty state message
- No vehicle selected → Details panel shows placeholder
- Double-click prevention → isPurchasing flag blocks
- Long names → CSS handles with overflow
- Mobile view → Responsive design adapts
- ESC key → Handler in script.js (backup)

### Potential Issues
- **Firefox scrollbar:** Custom scrollbar uses webkit (fallback to default)
- **Very old browsers:** ES6 features may not work (requires modern browser)
- **High DPI screens:** May need testing for scaling

---

## Performance Benchmarks

### Expected Performance
- **Load time:** < 50ms (all inline assets)
- **UI open:** 300ms animation
- **UI close:** 200ms animation
- **Selection change:** Instant (< 10ms)
- **Scrolling:** 60 FPS smooth

### Memory Usage
- **HTML:** 1.7 KB
- **CSS:** 12 KB
- **JavaScript:** 12 KB
- **Total:** ~26 KB (negligible)
- **Runtime memory:** < 1 MB

---

## Checklist for UX Designer Review

Visual Appearance:
- [ ] Transparent backgrounds (no black boxes)
- [ ] Green accent color (#00ff88) correct
- [ ] Text shadows visible on ALL text
- [ ] Two-panel layout (55/45 split)
- [ ] Typography sizes match spec
- [ ] Hover effects smooth
- [ ] Selected state clearly visible
- [ ] Animations smooth and appropriate timing

Functionality:
- [ ] Auto-select first vehicle works
- [ ] Click to select changes vehicle
- [ ] Purchase button states correct
- [ ] Feedback messages display correctly
- [ ] Timing correct (3s success, 5s error)
- [ ] Close button works
- [ ] ESC key works
- [ ] Loading state displays during purchase

Responsive:
- [ ] Desktop view looks good
- [ ] Tablet view (768px) switches to single column
- [ ] Mobile view (480px) reduces sizes appropriately
- [ ] No horizontal scrolling
- [ ] All content visible at all sizes

Edge Cases:
- [ ] Empty list handled gracefully
- [ ] Long names don't break layout
- [ ] Rapid clicking prevented
- [ ] Scrolling works with many vehicles

---

## Sign-Off

**Frontend UI Engineer:** ✓ Implementation Complete  
**Date:** January 24, 2026  
**Status:** Ready for UX Designer Review  
**Next Step:** Submit to UX Designer for visual approval  

---

*Visual Testing Reference - my_dealership NUI*
