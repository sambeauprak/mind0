# Mind0 — macOS Mindmapping App

A native macOS mindmapping application built with **SwiftUI**. Create, arrange, and style mind maps with a Figma-like canvas, collapsible nodes, multiple layouts, image support, theme system, and SVG/Markdown export.

![Platform](https://img.shields.io/badge/platform-macOS_14%2B-blue)
![Swift](https://img.shields.io/badge/swift-5.9-orange)

---

## Features

### Canvas
- **Figma-like navigation** — drag to pan, `⌘` + scroll to zoom
- **Fixed node positions** — nodes are arranged by auto-layout algorithms
- **Curved bezier connections** — smooth lines between parent and child nodes
- **Auto-layout** — one-click Radial (center) and Tree (left-to-right columns) layouts

### Nodes
- **Collapsible parent nodes** — toggle collapse/expand with a button overlay
- **Card representation** — title text + optional image in every node
- **4 node shapes** — Rounded Rectangle, Ellipse, Capsule, Rectangle
- **Background color** — 8 primary colors, 8 pastel alternatives, or a custom NSColorPicker
- **Line color** — independent per-node line color for connections
- **Image support** — add images via context menu, click for zoomable preview
- **Trello-style cover mode** — image fills the card with a transparent title overlay

### Documents
- **Document management** — multiple documents listed in a collapsible sidebar
- **Auto-save** — every change persists immediately to `~/Documents/Mind0/*.mind0`
- **Collapsible node tree** — navigate the full hierarchy from the sidebar

### Themes
- **8 preset themes**: Default, Nature, Ocean, Sunset, Midnight, Trello Covers, Minimal, Vibrant
- Each theme controls: node shape, line color, canvas background, node background, text color, image cover mode
- Apply a theme to instantly restyle the entire map

### Export
- **SVG** — vector format with embedded images, curved paths, and clip paths
- **Markdown** — one `.md` file per node, with parent/child cross-links

### Keyboard Shortcuts

| Shortcut | Action |
|---|---|
| `⌘N` | Add child to selected node |
| `⌘⌫` | Delete selected node |
| `⌘⇧C` | Toggle collapse |
| `⌘⌥1` | Radial layout |
| `⌘⌥2` | Tree layout |
| `⌘⇧E` | Export as SVG |
| `⌘⇧M` | Export as Markdown |

---

## Architecture

```
scripts/
└── build-dmg.sh            # Release DMG packaging script

Sources/Mind0/
├── Mind0App.swift           # @main entry point + menu commands
├── Models/
│   ├── MindNode.swift       # Node data model, AnyShape, Color+hex
│   ├── MindDocument.swift   # Document model + JSON persistence layer
│   ├── Theme.swift          # Theme model with 8 presets
│   └── LayoutEngine.swift   # Radial and Tree layout algorithms
├── ViewModels/
│   └── AppState.swift       # Central ObservableObject (single source of truth)
├── Views/
│   ├── ContentView.swift     # HSplitView layout + toolbar overlay
│   ├── CanvasView.swift     # Pan/zoom canvas with ConnectionLinesView
│   ├── NodeCardView.swift    # Stylable node card with image support
│   ├── SidebarView.swift    # Document list + collapsible node tree
│   ├── ColorPickerView.swift # Color swatches + custom picker
│   ├── ImagePreviewView.swift # Full-screen zoombox overlay
│   ├── ThemeEditorView.swift  # Theme selection grid
│   └── ExportPanelView.swift  # Export format chooser
└── Utilities/
    ├── SVGExporter.swift     # SVG string generator
    └── MarkdownExporter.swift # One .md per node with cross-links
```

### Tech Stack

| Layer | Technology |
|---|---|
| Language | Swift 5.9 |
| UI Framework | SwiftUI (macOS 14 SDK) |
| Build Tool | Swift Package Manager |
| Persistence | JSON files in `~/Documents/Mind0/` |
| Image Handling | `NSImage` with TIFF serialization |
| Canvas Rendering | `@ViewBuilder` + `Path` + `scaleEffect`/`offset` transforms |

### Data Flow

```
User Input → Views (gestures/taps)
                ↓
          AppState (ObservableObject)
                ↓
          MindDocument (Codable model)
                ↓
          ~/Documents/Mind0/*.mind0 (JSON)
```

All state lives in `AppState`, an `@EnvironmentObject` injected into every view. Mutations flow through `AppState` methods, which update the model and trigger `objectWillChange` for SwiftUI re-rendering. Documents auto-save to the filesystem on every mutation.

---

## Build & Run

```bash
# Requires macOS 14+ and Xcode 15+ (or Swift 5.9+ toolchain)

cd mind0
swift run          # Build and launch the app
swift build        # Build only (no run)
swift package clean  # Clean build artifacts
```

The first build will download no dependencies — Mind0 uses only Apple SDK frameworks.

### Building a Release DMG

```bash
./scripts/build-dmg.sh
```

This produces `Mind0.dmg` at the project root — a compressed disk image containing `Mind0.app` with a bundled `Info.plist` and all resources. It builds in release mode, signs the app ad-hoc, and uses `hdiutil` for DMG creation.

---

## Future Ideas

- Undo/redo support
- Drag-and-drop node re-parenting
- Rich text in node titles
- iCloud / CloudKit sync
- Export to PNG/PDF
- Custom node icons
- Search/filter across documents
- Multi-select and bulk operations
- Mini-map overview
