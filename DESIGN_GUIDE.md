# Horcrux Design Guide (horcrux3 Theme)

## Design Philosophy

**Keywords**: Stark monochrome, terminal-inspired, brutalist, confident typography, high contrast

The horcrux3 theme emphasizes a **minimalist, brutalist aesthetic** with a stark black and white palette. The design is deliberately restrained, using only shades of gray for UI elements. Both system light and dark modes are supported.

---

## Color Palette

### Light Mode
- **Background** `#f4f4f4` - Main scaffold background (light gray)
- **Primary Text** `#0e0c0d` - Main body text, headings (near black)
- **Secondary Text** `#808080` - Subtitles, labels, helper text (medium gray)
- **Divider** `#E0E0E0` - Dividers, borders (light gray)
- **Surface** `#FAFAFA` - Cards, elevated surfaces
- **Button** `#808080` - Primary button background (medium gray)
- **Button Text** `#f4f4f4` - Text on buttons (light gray)

### Dark Mode
- **Background** `#0e0c0d` - Main scaffold background (near black)
- **Primary Text** `#f4f4f4` - Main body text, headings (light gray)
- **Secondary Text** `#808080` - Subtitles, labels, helper text (medium gray)
- **Divider** `#333333` - Dividers, borders (dark gray)
- **Surface** `#1A1A1A` - Cards, elevated surfaces
- **Button** `#404040` - Primary button background (dark gray)
- **Button Text** `#f4f4f4` - Text on buttons (light gray)

### System Colors
- **Error** `#BA1A1A` - Error states, validation messages
- Both modes use the same error color for consistency

---

## Typography

### Font Families
- **Body Text**: Fira Sans - Clean, readable, modern sans-serif
- **Titles/Headings**: Archivo - Confident, strong presence
- **Monospace**: RobotoMono - For technical content, keys, addresses (unchanged)

### Type Scale
```
displaySmall:   28pt, Archivo, weight 700
headlineSmall:  22pt, Archivo, weight 500
titleLarge:     22pt, Archivo, weight 600
bodyLarge:      14pt, Fira Sans, weight 500
bodyMedium:     14pt, Fira Sans, weight 400
bodySmall:      12pt, Fira Sans, weight 400
labelSmall:     12pt, Fira Sans, weight 500
labelMedium:    Fira Sans, weight 600
```

### AppBar Typography
- **Size**: 40pt
- **Weight**: 500 (medium)
- **Font**: Archivo
- **Alignment**: Left (not centered)
- **Height**: 100pt toolbar
- **Title Spacing**: 32pt
- **Leading Width**: 32pt

---

## Visual Style

### Shapes & Rounding
- **Minimal Rounding**: Brutalist, flat aesthetic
  - **Form fields**: 4pt border radius
  - **Cards**: 4pt border radius
  - **Buttons**: 12pt border radius
  - **List items**: 4pt border radius (subtle)

### Elevation & Borders
- **Cards**: 0 elevation, no borders, transparent surface tint
- **List Tiles**: No borders, no elevation, separated by thin dividers
- **Form Fields**: YES borders (subtle outline matching theme)
- **Buttons**: Outlined style with subtle fill and shadow (2pt elevation)
- **Dividers**: 0.5pt thickness (razor thin)

### Spacing
- Generous vertical spacing between sections
- Standard padding: 16pt
- Large titles create significant visual hierarchy

---

## Component Patterns

### RowButton (Primary Actions)
**Usage**: Single primary action at bottom of screen
- **Style**: Outlined with subtle fill and shadow
- **Background**: Theme button color (light: `#808080`, dark: `#404040`)
- **Border**: 1pt border matching background color
- **Text**: Light gray `#f4f4f4` (both modes)
- **Icon**: Same color as text
- **Full width**, fixed at bottom
- **Height**: 56pt minimum
- **Elevation**: 2pt subtle shadow
- **Disabled state**: Reduced opacity, theme-aware

**Example**: "Create Vault", "Save", main screen actions

### RowButtonStack (Multiple Actions)
**Usage**: Multiple actions at bottom of screen
- **Gradient**: Theme-based gray gradient
  - **Light mode**: Darker grays at top → Medium gray at bottom
    - Top buttons: `#606060`
    - Middle buttons: Interpolated between `#606060` and `#707070`
    - Bottom button: `#808080` (primary)
  - **Dark mode**: Lighter grays at top → Medium gray at bottom
    - Top buttons: `#606060`
    - Middle buttons: Interpolated between `#606060` and `#505050`
    - Bottom button: `#404040` (primary)
- All buttons use **onSurface** text color for contrast
- **Monotonic gradient**: Colors progress smoothly without visual "dips"
- Fixed at bottom of screen
- Each button has outlined style with subtle shadow

**When to use**: 
- 2+ actions needed (e.g., Edit, Settings, Create)
- Actions are contextual to current screen
- Primary action goes at bottom (darkest in stack)

### Buttons (Non-Primary)
**ElevatedButton**: Theme button background
- Theme-aware gray color (light: `#808080`, dark: `#404040`)
- Light text `#f4f4f4` on button background
- 2pt elevation with subtle shadow
- 12pt border radius

**OutlinedButton**: Primary text color border
- Border matches primary text (light: `#0e0c0d`, dark: `#f4f4f4`)
- 1pt border width
- Text matches primary text color
- No fill, transparent background
- 12pt border radius

**TextButton**: Primary text color
- Minimal style with no background or border
- Text matches primary text color
- 12pt border radius
- For tertiary/minimal actions

### Form Fields
- **Background**: Match scaffold (light: `#f4f4f4`, dark: `#0e0c0d`)
- **Border**: Yes, subtle outline using divider color
  - Light mode: `#E0E0E0` (1pt)
  - Dark mode: `#333333` (1pt)
- **Focused Border**: Primary text color, 1.5pt width
  - Light mode: `#0e0c0d`
  - Dark mode: `#f4f4f4`
- **Error Border**: `#BA1A1A`, 1pt width
- **Label**: Archivo font, secondary text color with 60% opacity
- **Hint Text**: Secondary text `#808080` at 60% opacity
- **Filled**: Yes (matches scaffold)
- **Border Radius**: 4pt

### List Items
- **Background**: Match scaffold (light: `#f4f4f4`, dark: `#0e0c0d`)
- **Dividers**: Thin dividers between items (0.5pt thickness)
  - Light mode: `#E0E0E0`
  - Dark mode: `#333333`
- **No borders** on individual items
- **No elevation**
- **No cards** wrapping them
- **Icon background**: Surface container (light: `#FAFAFA`, dark: `#1A1A1A`)
- **Icon color**: Primary text color (high contrast)
  - Light mode: `#0e0c0d`
  - Dark mode: `#f4f4f4`
- **Title**: Archivo font, weight 700, 16pt, primary text color
- **Subtitle**: Fira Sans font, 12pt, secondary text `#808080`
- **Border Radius**: 4pt (subtle)

### Cards
- **Background**: Match scaffold (light: `#f4f4f4`, dark: `#0e0c0d`)
- **Surface Tint**: Transparent (prevents Material 3 bluish tint)
- **Border**: None
- **Elevation**: 0
- **Border Radius**: 4pt
- **Margin**: Zero (edge-to-edge by default)
- **Use**: For grouping form sections, settings panels

---

## Layout Patterns

### Screen Structure
```
┌─────────────────────────┐
│ AppBar (large, left)    │ ← 100pt tall, 40pt text
├─────────────────────────┤
│                         │
│   Scrollable Content    │ ← Main content area
│                         │
│   [Cards, Lists, etc]   │
│                         │
├─────────────────────────┤
│   RowButton(Stack)      │ ← Fixed at bottom
└─────────────────────────┘
```

### Content Padding
- **Screen edges**: 16pt horizontal padding
- **Between sections**: 16pt vertical spacing
- **Within cards**: 16pt padding

### AppBar Style
- **Background**: Match scaffold (theme-aware)
- **Text**: Primary text color (theme-aware)
- **Surface Tint**: Transparent (prevents color changes on scroll)
- **centerTitle**: false (always left-aligned)
- **No elevation**

---

## Color Usage Rules

### Monochrome Philosophy
**Horcrux3 uses only grayscale colors - no accent colors.**
- All UI elements use shades of gray
- High contrast between text and background
- Subtle shadows provide depth (2pt elevation on buttons)
- Error states use red `#BA1A1A` as the only exception

### Theme Awareness
All colors adapt to system theme (light/dark mode):
- **Background**: Inverts between near-white and near-black
- **Text**: Inverts to maintain contrast
- **Buttons**: Use medium grays in both modes
- **Dividers**: Subtle grays matching theme brightness
- **Secondary text**: `#808080` in both modes (universal mid-gray)

### Button Gradients
When multiple buttons appear in **RowButtonStack**:
- Colors form a monotonic gradient (no visual "dips")
- Lighter/brighter at top → darker/dimmer at bottom
- Bottom button is always the primary action
- All buttons maintain high contrast with background

### Minimalist Design
- No unnecessary colors or decorations
- Flat design with minimal shadows
- Focus on typography and spacing for hierarchy
- Gray is powerful when used intentionally

---

## Common Patterns

### Screen with Primary Action
```dart
Scaffold(
  appBar: AppBar(title: Text('Large Title')),
  body: Column(
    children: [
      Expanded(child: SingleChildScrollView(...)),
      RowButton(
        onPressed: () {},
        icon: Icons.add,
        text: 'Primary Action',
      ),
    ],
  ),
)
```

### Screen with Multiple Actions
```dart
// Bottom of screen
RowButtonStack(
  buttons: [
    RowButtonConfig(/* secondary */),
    RowButtonConfig(/* secondary */),
    RowButtonConfig(/* primary - will be orange */),
  ],
)
```

### Form Section
```dart
Card(
  child: Padding(
    padding: EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Section Title',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        SizedBox(height: 16),
        TextField(
          decoration: InputDecoration(
            labelText: 'Field Label',
            hintText: 'Hint text',
            filled: true,
          ),
        ),
      ],
    ),
  ),
)
```

### List of Items
```dart
// Use ListView.separated to add dividers between items
ListView.separated(
  itemBuilder: (context, index) => ListTile(
    leading: Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.key,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    ),
    title: Text('Item title'),
    subtitle: Text('Item subtitle'),
    trailing: Icon(Icons.chevron_right),
  ),
  separatorBuilder: (context, index) => Divider(
    height: 1,
    thickness: 0.5,
  ),
  itemCount: items.length,
)
```

---

## Design Inspirations

- **Brutalist Design**: Raw, honest materials, stark contrasts
- **Terminal UIs**: Monochrome, confident typography, functional first
- **Print Design**: High contrast black and white, strong hierarchy
- **Modernist Architecture**: "Less is more", essential elements only
- **E-ink Displays**: Clear, readable, no distractions

---

## Things to Avoid

- ❌ Using any accent colors (stay monochrome)
- ❌ Excessive rounding (keep it minimal: 4pt or 12pt)
- ❌ Borders on individual list items (use dividers instead)
- ❌ Cards wrapping individual list items
- ❌ Centered AppBar titles (always left-aligned)
- ❌ Colorful UI elements beyond grayscale
- ❌ Heavy shadows (keep to 2pt max)
- ❌ Small or timid typography
- ❌ Non-monotonic button gradients
- ❌ Material 3 surface tints (keep transparent)

---

## System Theme Support

### Light Mode
- Default appearance for bright environments
- Light gray background `#f4f4f4` with near-black text `#0e0c0d`
- Medium gray buttons `#808080` for balanced visibility
- Subtle dividers `#E0E0E0` that don't overwhelm

### Dark Mode
- Automatically activates based on system settings
- Near-black background `#0e0c0d` with light gray text `#f4f4f4`
- Medium gray buttons `#404040` that don't blind in darkness
- Darker dividers `#333333` for subtle separation

### Theme Switching
- App uses `ThemeMode.system` to follow device preferences
- All components are theme-aware via `Theme.of(context).colorScheme`
- No hardcoded colors - everything adapts automatically
- Consistent experience across light/dark with same design philosophy

---

## Quick Reference Card

### Light Mode
| Element | Color | Font | Size |
|---------|-------|------|------|
| Background | Light gray `#f4f4f4` | - | - |
| Primary Text | Near-black `#0e0c0d` | Fira Sans | 14pt |
| Secondary Text | Medium gray `#808080` | Fira Sans | 12pt |
| AppBar Title | Near-black `#0e0c0d` | Archivo | 40pt / 500 |
| Primary Action | Medium gray `#808080` | Fira Sans | 56pt height |
| Button Text | Light gray `#f4f4f4` | Fira Sans | - |
| Form Border | Light gray `#E0E0E0` | - | 1pt |
| Focused Border | Near-black `#0e0c0d` | - | 1.5pt |
| Divider | Light gray `#E0E0E0` | - | 0.5pt |
| Surface | Off-white `#FAFAFA` | - | - |

### Dark Mode
| Element | Color | Font | Size |
|---------|-------|------|------|
| Background | Near-black `#0e0c0d` | - | - |
| Primary Text | Light gray `#f4f4f4` | Fira Sans | 14pt |
| Secondary Text | Medium gray `#808080` | Fira Sans | 12pt |
| AppBar Title | Light gray `#f4f4f4` | Archivo | 40pt / 500 |
| Primary Action | Dark gray `#404040` | Fira Sans | 56pt height |
| Button Text | Light gray `#f4f4f4` | Fira Sans | - |
| Form Border | Dark gray `#333333` | - | 1pt |
| Focused Border | Light gray `#f4f4f4` | - | 1.5pt |
| Divider | Dark gray `#333333` | - | 0.5pt |
| Surface | Dark gray `#1A1A1A` | - | - |

---

**Remember**: The design is intentionally stark and minimal. Grayscale is powerful. High contrast is essential. Typography and spacing create all hierarchy. Let the content shine.

