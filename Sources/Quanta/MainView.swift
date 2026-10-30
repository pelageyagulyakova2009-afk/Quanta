import SceneKit
import SwiftUI

struct SceneContainer: NSViewRepresentable {
    let manager: SceneManager

    func makeNSView(context: Context) -> QuantaSCNView {
        let v = QuantaSCNView(frame: .zero)
        v.manager = manager
        v.scene = manager.scene
        v.pointOfView = manager.cameraNode
        v.delegate = manager
        v.backgroundColor = .clear
        v.wantsLayer = true
        v.layer?.isOpaque = false
        v.antialiasingMode = .multisampling4X
        v.preferredFramesPerSecond = 60
        v.rendersContinuously = true
        v.isPlaying = true
        return v
    }

    func updateNSView(_ nsView: QuantaSCNView, context: Context) {}
}

struct MainView: View {
    @ObservedObject var manager: SceneManager
    @ObservedObject var follow: FollowState
    var onQuit: () -> Void

    var body: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 28)
                .fill(Color.black.opacity(0.35))
                .overlay(RoundedRectangle(cornerRadius: 28).stroke(Color.cyan.opacity(0.35), lineWidth: 1))
                .shadow(color: .cyan.opacity(0.25), radius: 20)

            SceneContainer(manager: manager)
                .clipShape(RoundedRectangle(cornerRadius: 28))

            toolbar.padding(.top, 14)

            HStack {
                searchField
                Spacer()
            }
            .padding(.leading, 18)
            .padding(.top, 16)

            VStack {
                Spacer()
                temperature
            }
            .padding(.bottom, 16)
            .padding(.horizontal, 28)

            if let e = manager.hoveredElement {
                VStack {
                    Spacer()
                    Text("\(e.number) · \(e.name) · \(e.elementCategory.title)")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundStyle(e.elementCategory.color)
                        .padding(.horizontal, 14).padding(.vertical, 6)
                        .background(.ultraThinMaterial, in: Capsule())
                        .padding(.bottom, 58)
                }
                .allowsHitTesting(false)
            }
        }
        .preferredColorScheme(.dark)
    }

    private var toolbar: some View {
        HStack(spacing: 8) {
            ForEach(LayoutMode.allCases) { m in
                let active = manager.mode == m
                Button { manager.setMode(m) } label: {
                    Label(m.rawValue, systemImage: m.icon)
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .foregroundStyle(active ? Color.black : Color.cyan)
                        .background(Capsule().fill(active ? Color.cyan : Color.cyan.opacity(0.08)))
                        .overlay(Capsule().stroke(Color.cyan.opacity(0.8), lineWidth: 1))
                        .shadow(color: .cyan.opacity(active ? 0.9 : 0.3), radius: active ? 10 : 4)
                }
                .buttonStyle(.plain)
            }
            Divider().frame(height: 18).overlay(Color.cyan.opacity(0.4))
            Button { follow.enabled.toggle() } label: {
                Image(systemName: "pin.fill")
                    .font(.system(size: 12, weight: .bold))
                    .frame(width: 26, height: 26)
                    .foregroundStyle(follow.enabled ? Color.cyan : Color.pink)
                    .background(Circle().fill((follow.enabled ? Color.cyan : Color.pink).opacity(0.12)))
                    .overlay(Circle().stroke(follow.enabled ? Color.cyan.opacity(0.7) : Color.pink, lineWidth: 1))
                    .shadow(color: follow.enabled ? .clear : .pink, radius: follow.enabled ? 0 : 8)
            }
            .buttonStyle(.plain)
            .help(follow.enabled ? "Закрепить" : "Следовать за курсором")
            iconButton("xmark", help: "Выход", action: onQuit)
        }
        .padding(6)
        .background(.ultraThinMaterial, in: Capsule())
    }

    private var searchField: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass").foregroundStyle(Color.cyan)
            TextField("Поиск", text: $manager.query)
                .textFieldStyle(.plain)
                .font(.system(size: 12, design: .monospaced))
                .frame(width: 120)
        }
        .padding(.horizontal, 10).padding(.vertical, 6)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().stroke(Color.cyan.opacity(0.5), lineWidth: 1))
    }

    private var temperature: some View {
        HStack(spacing: 10) {
            Text("T").font(.system(size: 11, weight: .bold, design: .monospaced)).foregroundStyle(Color.cyan)
            Slider(value: $manager.temperatureC, in: -200...4000)
                .tint(.cyan)
            Text("\(Int(manager.temperatureC)) °C")
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.white.opacity(0.7))
                .frame(width: 72, alignment: .trailing)
        }
        .padding(.horizontal, 14).padding(.vertical, 6)
        .background(.ultraThinMaterial, in: Capsule())
    }

    private func iconButton(_ name: String, help: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: name)
                .font(.system(size: 11, weight: .bold))
                .frame(width: 26, height: 26)
                .foregroundStyle(Color.pink)
                .background(Circle().fill(Color.pink.opacity(0.1)))
                .overlay(Circle().stroke(Color.pink.opacity(0.7), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .help(help)
    }
}
