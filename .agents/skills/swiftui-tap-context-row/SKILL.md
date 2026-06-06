---
name: swiftui-tap-context-row
description: >-
  Build SwiftUI rows and cards with tap (primary action) and long-press context
  menus: full-width hit testing, press feedback, and Liquid Glass compatibility.
  Use when implementing tappable list rows, context menus on custom views, dead
  tap zones, missing press feedback, double animations on long press, or
  Button + contextMenu gesture conflicts.
---

# SwiftUI Tap + Context Menu Row

## When to use

Apply this skill when a custom row/card needs:

- **Tap** → primary action (toggle, navigate, select)
- **Long press** → `.contextMenu` with secondary actions
- **Full-row hit area** including gaps, spacers, and padding
- **Press feedback** on tap without breaking context menu lift animation

## Choose a pattern

| Row shape | Pattern |
|-----------|---------|
| Full-width card with internal `Spacer`, glass/material background | **Gesture row** (below) |
| Compact chip, toolbar control, content-sized button | **`Button` + `.contextMenu`** |

Do not use one pattern for both without checking hit area and gesture behavior.

---

## Gesture row (full-width cards)

Use for list rows where the visual card is wider than its text content.

### Layer responsibilities

Split the row into two layers:

1. **Content view** — layout, styling, background/glass. No gestures.
2. **Interaction wrapper** — hit shape, press feedback, tap, context menu, accessibility.

### Content view requirements

```swift
private struct ItemRow: View {
    // ... properties

    var body: some View {
        rowContent
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)  // Required
            .backgroundStyle()  // glass, material, fill — non-interactive
    }
}
```

- **`.frame(maxWidth: .infinity, alignment: .leading)`** — row spans container width; without it, only text/icons receive taps.
- **Do not put `.interactive()` on Liquid Glass** when the row also has `.contextMenu`. Glass press animation and context menu lift animate together (double animation).

### Interaction wrapper (apply in this order)

```swift
ForEach(items) { item in
    ItemRow(item: item)
        .contentShape(.interaction, rowShape)
        .contentShape(.contextMenuPreview, rowShape)
        .pressFeedback { primaryAction(item) }
        .contextMenu { contextMenuContent(for: item) }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(label(for: item))
        .accessibilityHint(hint(for: item))
}
```

- **`contentShape(.interaction, …)`** — makes the full card tappable, not just visible subviews.
- **`contentShape(.contextMenuPreview, …)`** — context menu preview matches the card shape.
- **`pressFeedback { action }`** — tap action and press-down visual feedback in one modifier (see [references/press-feedback.md](references/press-feedback.md)).
- **`onTapGesture` + `.contextMenu`** — preferred over `Button` for full-width gesture rows (see pitfalls).

Use the same `Shape` (e.g. `RoundedRectangle(cornerRadius: 20, style: .continuous)`) for both content shapes.

---

## Button row (compact controls)

Use when the control is content-sized (chip, pill, icon button):

```swift
Button(action: primaryAction) {
    ChipLabel(title: title)
}
.buttonStyle(.plain)
.contextMenu { secondaryActions }
.accessibilityLabel(label)
```

`Button` provides tap handling and accessibility. Context menu on compact controls usually works because there is no dead space inside the label.

---

## Pitfalls (do not combine)

| Mistake | Symptom | Fix |
|---------|---------|-----|
| `Button` + `.contextMenu` on full-width row | Long press never opens menu | Use gesture row pattern |
| No `.frame(maxWidth: .infinity)` | Taps only on text/icons | Add frame on content view |
| No `.contentShape(.interaction, …)` | Dead zones around spacers | Add interaction content shape on wrapper |
| `.glassEffect(.interactive())` + `.contextMenu` | Double animation on long press | Non-interactive glass + `.pressFeedback { ... }` |
| `onTapGesture` + `onLongPressGesture(pressing:)` | No press feedback on quick taps | Single `DragGesture` for press + tap with duration guard |
| Accessibility on inner content + outer gestures | Duplicate or missing VoiceOver traits | Put a11y on interaction wrapper |

---

## Liquid Glass note

For iOS 26+ glass surfaces on tappable rows:

```swift
// Content view — visual only
.glassEffect(.regular.tint(...), in: shape)  // NOT .interactive()

// Wrapper — gestures and press feedback
.pressFeedback { ... }
.onTapGesture { ... }
.contextMenu { ... }
```

Reserve `.interactive()` for standalone glass buttons with no context menu.

---

## Implementation checklist

When adding or reviewing a tap + context menu row:

- [ ] Content view has `.frame(maxWidth: .infinity, alignment: .leading)` (if full-width)
- [ ] Wrapper has `.contentShape(.interaction, …)` and `.contentShape(.contextMenuPreview, …)`
- [ ] Primary action on `.onTapGesture` (gesture row) or `Button` (compact row)
- [ ] `.contextMenu` on same view as tap gesture (gesture row) or on `Button` (compact row)
- [ ] `.pressFeedback { ... }` on gesture rows that need tap-down feedback
- [ ] Glass/material is non-interactive when context menu is present
- [ ] Accessibility label, hint, and traits on interaction wrapper
- [ ] Verify: tap empty padding, tap text, long press for menu, no double lift animation

---

## Reference files

- [references/press-feedback.md](references/press-feedback.md) — reusable `PressFeedbackModifier` and why it uses `simultaneousGesture`
- [references/examples.md](references/examples.md) — complete minimal examples for both patterns
