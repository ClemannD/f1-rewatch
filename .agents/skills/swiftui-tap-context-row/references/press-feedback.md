# Press Feedback Modifier

Tap-down feedback for gesture rows without blocking tap or context menu.

## Why not `Button`, interactive glass, or split gestures?

- **`Button` + `.contextMenu`** on full-width rows often prevents long press from reaching the context menu.
- **`.glassEffect(.interactive())`** animates on finger down; **`.contextMenu`** also lifts on long press → double animation.
- **`DragGesture` + outer `.onTapGesture`** — drag captures the touch; tap never fires.
- **`onTapGesture` + `onLongPressGesture(pressing:)`** — tap wins on quick touches; `pressing` never runs, so no feedback.

## Implementation

Use one `simultaneousGesture` that handles press visuals and tap detection:

```swift
private struct PressFeedbackModifier: ViewModifier {
    var onTap: () -> Void
    @State private var isPressed = false
    @State private var pressBeganAt: Date?

    private let tapMaxDuration: TimeInterval = 0.45
    private let tapMaxDistance: CGFloat = 20

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.985 : 1.0)
            .brightness(isPressed ? -0.035 : 0)
            .animation(.spring(response: 0.22, dampingFraction: 0.86), value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isPressed {
                            isPressed = true
                            pressBeganAt = Date()
                        }
                    }
                    .onEnded { value in
                        isPressed = false
                        defer { pressBeganAt = nil }

                        guard let began = pressBeganAt else { return }
                        let elapsed = Date().timeIntervalSince(began)
                        let distance = hypot(value.translation.width, value.translation.height)
                        guard elapsed < tapMaxDuration, distance < tapMaxDistance else { return }
                        onTap()
                    }
            )
    }
}

extension View {
    func pressFeedback(onTap: @escaping () -> Void) -> some View {
        modifier(PressFeedbackModifier(onTap: onTap))
    }
}
```

## How it works

- **`onChanged`** — finger down → press visuals immediately.
- **`onEnded`** — finger up → clear visuals; fire `onTap` only for short, stationary touches.
- **`tapMaxDuration`** — below context-menu threshold (~0.5s) so long-press release does not toggle.
- **`tapMaxDistance`** — ignore drags that became scrolls.
- **`simultaneousGesture`** — does not block scroll or `.contextMenu`.

## Modifier order

```swift
ItemRow(...)
    .contentShape(.interaction, shape)
    .contentShape(.contextMenuPreview, shape)
    .pressFeedback { primaryAction(item) }
    .contextMenu { ... }
```

## Pitfalls

| Approach | Problem |
|----------|---------|
| `DragGesture` + outer `.onTapGesture` | Tap never fires |
| `onTapGesture` + `onLongPressGesture(pressing:)` | No press feedback on quick taps |
| `DragGesture.onEnded` without duration guard | Long-press release toggles state |

## Tuning

Match existing app animations when possible:

```swift
.animation(.spring(response: 0.28, dampingFraction: 0.82), value: isPressed)
```

For stronger feedback, increase scale delta (e.g. `0.97`) or add `.opacity(isPressed ? 0.92 : 1.0)`.
