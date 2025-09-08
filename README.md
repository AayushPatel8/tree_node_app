# Tree Graph Explorer

A responsive, interactive Flutter app for visualizing and manipulating tree graphs. Create, explore, and manage tree structures with intuitive controls and elegant UI, optimized for mobile, tablet, and desktop.

<img width="1918" height="912" alt="image" src="https://github.com/user-attachments/assets/ca69d079-b3fd-49e0-a6b2-73b6cf19ddd3" />
---

## Features

- **Interactive Tree Manipulation:**  
  - Add child nodes to any node.
  - Delete any node except the root.
  - Reset tree to start fresh.
  - Tap to select active node.

- **Responsive Design:**  
  - Adapts to mobile, tablet, desktop, and large desktop breakpoints.
  - Controls and layout scale for better usability on any device.

- **Elegant UI:**  
  - Animated node transitions and selection effects.
  - Custom app bar and status bar show current node, depth, and count.
  - Watermark overlay with creator credit.
  - Gradient backgrounds, themed connectors, and grid lines.

- **Dark & Light Themes:**  
  - Toggle between dark and light mode.
  - Consistent color palettes for all UI elements.

- **Zoom & Pan:**  
  - Use pinch gesture or mouse wheel to zoom and pan the tree canvas.

- **Source Link:**  
  - GitHub button in-app links directly to this repository.

---

## Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install)
- Dart 3.x

### Clone and Run

```bash
git clone https://github.com/AayushPatel8/tree_node_app.git
cd tree_node_app
flutter pub get
flutter run
```

### Usage

- **Add Node:** Tap the ➕ icon (or floating action button on desktop) to add a child to the active node.
- **Delete Node:** Select any node (except root) and tap the 🗑️ icon to delete.
- **Reset Tree:** Tap the 🔄 icon to reset.
- **Theme Toggle:** Tap the 🌚/🌞 icon to switch between dark and light mode.
- **View Source:** Tap the `</>` icon to open this repo.
- **Zoom & Pan:** Drag, pinch, or scroll to move around the tree.

---

## Code Structure

All logic is in a single file for simplicity:

- **TreeNode Class:**  
  Represents each node; tracks parent, children, and position.

- **Responsive Utilities:**  
  `ResponsiveBreakpoints` and `ResponsiveDimensions` handle adaptive UI scaling.

- **TreePage Widget:**  
  Main stateful widget. Manages tree structure, theme, layout, and interactions.  
  Contains animation controllers for smooth UI transitions.

- **Custom Painters:**  
  - `_BackgroundPainter`: Draws faint grid background.
  - `_ConnectorPainter`: Draws connectors between nodes using smooth cubic paths.

- **UI Components:**  
  - App bar (with theme and GitHub controls)
  - Status bar (shows active node, depth, and total node count)
  - Watermark overlay (animated creator credit)
  - Node widgets with tap, scale, and delete controls

---

## Customization

- **Max tree depth:** Limited to 100 for performance.
- **Node appearance and colors:** Easily tweakable in the theme color getters.
- **Animations:** Controlled by `AnimationController` for nodes and watermark.

---

## Credits

Developed by [Aayush Patel](https://github.com/AayushPatel8).  
Reach out for suggestions or contributions!

---

## Links

- [Flutter Documentation](https://flutter.dev/docs)
- [url_launcher package](https://pub.dev/packages/url_launcher)
- [Material Design Icons](https://fonts.google.com/icons)

---

## Support

If you find this useful, star ⭐️ the repo or share feedback!

```
