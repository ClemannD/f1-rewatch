import SwiftUI

struct AppBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.04, green: 0.05, blue: 0.08),
                    Color(red: 0.11, green: 0.14, blue: 0.18),
                    Color(red: 0.20, green: 0.03, blue: 0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            AngularGradient(
                colors: [
                    .red.opacity(0.24),
                    .cyan.opacity(0.14),
                    .white.opacity(0.06),
                    .red.opacity(0.20)
                ],
                center: .topTrailing
            )
            .blur(radius: 64)
            .ignoresSafeArea()
        }
    }
}

struct GlassPanel<Content: View>: View {
    var radius: CGFloat = 28
    var padding: CGFloat = 16
    var prominence: GlassPanelProminence = .standard
    var interactive: Bool = false
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .glassPanelSurface(radius: radius, prominence: prominence, interactive: interactive)
    }
}

private struct GlassPanelSurfaceModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    var radius: CGFloat
    var prominence: GlassPanelProminence
    var interactive: Bool

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)

        if #available(iOS 26.0, *) {
            content
                .glassEffect(.regular.tint(prominence.glassTint(for: colorScheme)).interactive(interactive), in: shape)
        } else {
            content
                .background {
                    shape
                        .fill(prominence.fill)
                        .background(.regularMaterial, in: shape)
                        .shadow(color: .black.opacity(prominence.shadowOpacity), radius: 18, y: 10)
                }
                .overlay {
                    shape
                        .strokeBorder(prominence.stroke, lineWidth: 1)
                }
        }
    }
}

enum GlassPanelProminence {
    case standard
    case row

    var fill: Color {
        switch self {
        case .standard:
            Color.black.opacity(0.24)
        case .row:
            Color(red: 0.05, green: 0.06, blue: 0.08).opacity(0.58)
        }
    }

    func glassTint(for colorScheme: ColorScheme) -> Color {
        switch self {
        case .standard:
            colorScheme == .light ? .black.opacity(0.22) : .white.opacity(0.08)
        case .row:
            colorScheme == .light ? .black.opacity(0.36) : .black.opacity(0.12)
        }
    }

    var stroke: Color {
        switch self {
        case .standard:
            .white.opacity(0.22)
        case .row:
            .white.opacity(0.26)
        }
    }

    var shadowOpacity: Double {
        switch self {
        case .standard:
            0.22
        case .row:
            0.34
        }
    }
}

struct CompactGlassButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.buttonStyle(.glass)
        } else {
            content.buttonStyle(.bordered)
        }
    }
}

struct ProminentGlassButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.buttonStyle(.glassProminent)
        } else {
            content.buttonStyle(.borderedProminent)
        }
    }
}

private struct PressFeedbackModifier: ViewModifier {
    @GestureState private var isPressed = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.985 : 1.0)
            .brightness(isPressed ? -0.035 : 0)
            .animation(.spring(response: 0.22, dampingFraction: 0.86), value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .updating($isPressed) { _, state, _ in
                        state = true
                    }
            )
    }
}

extension View {
    func glassPanelSurface(
        radius: CGFloat = 28,
        prominence: GlassPanelProminence = .standard,
        interactive: Bool = false
    ) -> some View {
        modifier(GlassPanelSurfaceModifier(radius: radius, prominence: prominence, interactive: interactive))
    }

    func compactGlassButton() -> some View {
        modifier(CompactGlassButtonModifier())
    }

    func prominentGlassButton() -> some View {
        modifier(ProminentGlassButtonModifier())
    }

    func pressFeedback() -> some View {
        modifier(PressFeedbackModifier())
    }
}

struct ProgressRing: View {
    @Environment(\.colorScheme) private var colorScheme
    @ScaledMetric(relativeTo: .headline) private var ringSize = 72.0
    @ScaledMetric(relativeTo: .headline) private var lineWidth = 10.0
    let progress: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(trackColor, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    Color.accentColor,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            Text("\(Int(progress * 100))%")
                .font(.system(.headline, design: .rounded, weight: .bold))
                .foregroundStyle(percentColor)
        }
        .frame(width: ringSize, height: ringSize)
        .accessibilityLabel("Progress \(Int(progress * 100)) percent")
    }

    private var trackColor: Color {
        colorScheme == .light ? Color.black.opacity(0.14) : .white.opacity(0.14)
    }

    private var percentColor: Color {
        colorScheme == .light ? Color.black.opacity(0.82) : .white
    }
}
