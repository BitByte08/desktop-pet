// SettingsView.swift
// Per-pet settings panel with all configurable options.

import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @ObservedObject var settings: AppSettings
    var onImport: () -> Void
    var onRemove: () -> Void
    var onQuit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {

            // ── Header ────────────────────────────────────────────────────
            HStack {
                TextField("Name", text: $settings.label)
                    .textFieldStyle(.roundedBorder)
                    .font(.headline)
                Spacer()
                Button("Import…", action: onImport)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
            }

            Divider()

            // ── Playback ─────────────────────────────────────────────────
            SectionHeader("Playback")

            Toggle("Playing", isOn: $settings.playing)

            LabeledSlider(label: "Speed",
                          value: $settings.speed,
                          range: 0.1...4.0,
                          format: "%.1fx")

            Divider()

            // ── Appearance ────────────────────────────────────────────────
            SectionHeader("Appearance")

            LabeledSlider(label: "Opacity",
                          value: $settings.opacity,
                          range: 0.1...1.0,
                          format: "%.0f%%",
                          displayMultiplier: 100)

            LabeledSlider(label: "Scale",
                          value: $settings.scale,
                          range: 0.25...4.0,
                          format: "%.2fx")

            HStack(spacing: 16) {
                Toggle("Flip H", isOn: $settings.flipHorizontal)
                Toggle("Flip V", isOn: $settings.flipVertical)
            }

            Divider()

            // ── Behavior ─────────────────────────────────────────────────
            SectionHeader("Behavior")

            Toggle("Always on Top",  isOn: $settings.alwaysOnTop)
            Toggle("Click-Through",  isOn: $settings.clickThrough)
            Toggle("Lock Position",  isOn: $settings.lockPosition)

            Divider()

            // ── System ────────────────────────────────────────────────────
            StartAtLoginToggle()

            Divider()

            // ── Bottom buttons ────────────────────────────────────────────
            HStack {
                Button(role: .destructive, action: onRemove) {
                    Label("Remove Pet", systemImage: "trash")
                }
                .buttonStyle(.plain)
                .foregroundColor(.red)
                Spacer()
                Button("Quit", action: onQuit)
                    .foregroundColor(.red)
            }
        }
        .padding(16)
        .frame(width: 280)
    }
}

// MARK: - Section header

private struct SectionHeader: View {
    let title: String
    init(_ title: String) { self.title = title }
    var body: some View {
        Text(title)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(.secondary)
            .textCase(.uppercase)
    }
}

// MARK: - Labeled Slider

private struct LabeledSlider: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let format: String
    var displayMultiplier: Double = 1.0

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(String(format: format, value * displayMultiplier))
                    .font(.caption.monospacedDigit())
                    .foregroundColor(.secondary)
            }
            Slider(value: $value, in: range)
        }
    }
}

// MARK: - Start at Login Toggle

private struct StartAtLoginToggle: View {
    @State private var isEnabled: Bool = false

    var body: some View {
        Toggle("Start at Login", isOn: $isEnabled)
            .onAppear { isEnabled = SMAppService.mainApp.status == .enabled }
            .onChange(of: isEnabled) { _, newValue in
                try? newValue ? SMAppService.mainApp.register()
                             : SMAppService.mainApp.unregister()
            }
    }
}
