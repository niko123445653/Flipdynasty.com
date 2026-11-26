import SwiftUI
import AppKit
import ApplicationServices
import CoreGraphics

@MainActor
final class ClickerModel: ObservableObject {
    @Published var isRunning = false
    @Published var clicks: UInt64 = 0
    @Published var cps: Double = 20
    @Published var permissionMissing = false

    private var timer: DispatchSourceTimer?

    func start() {
        guard AXIsProcessTrusted() else {
            permissionMissing = true
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
            _ = AXIsProcessTrustedWithOptions(options)
            return
        }

        stop()
        permissionMissing = false
        let source = DispatchSource.makeTimerSource(queue: .main)
        let interval = max(2, Int(1000.0 / cps))
        source.schedule(deadline: .now(), repeating: .milliseconds(interval), leeway: .milliseconds(1))
        source.setEventHandler { [weak self] in self?.clickAtPointer() }
        timer = source
        isRunning = true
        source.resume()
    }

    func stop() {
        timer?.setEventHandler {}
        timer?.cancel()
        timer = nil
        isRunning = false
    }

    func updateSpeed() {
        if isRunning { start() }
    }

    private func clickAtPointer() {
        guard let location = CGEvent(source: nil)?.location else { return }
        let down = CGEvent(mouseEventSource: nil, mouseType: .leftMouseDown, mouseCursorPosition: location, mouseButton: .left)
        let up = CGEvent(mouseEventSource: nil, mouseType: .leftMouseUp, mouseCursorPosition: location, mouseButton: .left)
        down?.post(tap: .cghidEventTap)
        up?.post(tap: .cghidEventTap)
        clicks &+= 1
    }
}

@main
struct MacAutoClickerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 360, minHeight: 440)
        }
        .windowResizability(.contentSize)
    }
}

struct ContentView: View {
    @StateObject private var model = ClickerModel()

    var body: some View {
        VStack(spacing: 22) {
            VStack(spacing: 6) {
                Image(systemName: "cursorarrow.click")
                    .font(.system(size: 38, weight: .semibold))
                    .foregroundStyle(.cyan)
                Text("NOVA CLICKER")
                    .font(.system(size: 25, weight: .black, design: .rounded))
                Text("Simple • Fast • AFK")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 8) {
                Text("\(model.clicks.formatted())")
                    .font(.system(size: 38, weight: .bold, design: .rounded).monospacedDigit())
                Text("TOTAL CLICKS")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(.quaternary.opacity(0.55), in: RoundedRectangle(cornerRadius: 18))

            VStack(spacing: 10) {
                HStack {
                    Text("Click speed")
                        .fontWeight(.semibold)
                    Spacer()
                    Text("\(Int(model.cps)) CPS")
                        .font(.system(.headline, design: .rounded).monospacedDigit())
                        .foregroundStyle(.cyan)
                }
                Slider(value: $model.cps, in: 1...500, step: 1) { _ in
                    model.updateSpeed()
                }
                HStack {
                    Text("1 CPS")
                    Spacer()
                    Text("500 CPS")
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }

            Button {
                if model.isRunning { model.stop() } else { model.start() }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: model.isRunning ? "stop.fill" : "play.fill")
                    Text(model.isRunning ? "STOP CLICKING" : "START AFK CLICKING")
                }
                .font(.headline.weight(.bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .foregroundStyle(.white)
                .background(model.isRunning ? Color.red : Color.green, in: RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)

            HStack(spacing: 8) {
                Circle()
                    .fill(model.isRunning ? .green : .secondary)
                    .frame(width: 8, height: 8)
                Text(model.isRunning ? "Running at cursor position" : "Stopped")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }

            if model.permissionMissing {
                VStack(spacing: 8) {
                    Text("Allow Accessibility access")
                        .font(.headline)
                    Text("In System Settings → Privacy & Security → Accessibility, enable NOVA CLICKER, then press Start again.")
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                    Button("Open Accessibility Settings") {
                        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                            NSWorkspace.shared.open(url)
                        }
                    }
                    .buttonStyle(.link)
                }
                .padding(12)
                .frame(maxWidth: .infinity)
                .background(.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
            }

            Text("Clicks wherever your mouse pointer is. Move the pointer to the spot you want, then start.")
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .padding(24)
        .preferredColorScheme(.dark)
        .onDisappear { model.stop() }
    }
}
