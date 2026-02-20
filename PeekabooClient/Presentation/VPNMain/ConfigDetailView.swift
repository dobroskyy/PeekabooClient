//
//  ConfigDetailView.swift
//  PeekabooClient
//
//  Presentation Layer - SwiftUI View
//

import SwiftUI

struct ConfigDetailView: View {

    let config: VPNConfiguration
    let onDelete: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var showingDeleteAlert = false

    var body: some View {
        List {
            Section("Основное") {
                LabeledContent("Название", value: config.name)
                LabeledContent("Адрес", value: config.serverAddress)
                LabeledContent("Порт", value: "\(config.serverPort)")
                LabeledContent("Транспорт", value: config.transport.rawValue.uppercased())
            }

            if case .vless(let reality) = config.protocol {
                Section("Reality") {
                    LabeledContent("Public Key", value: reality.publicKey)
                    LabeledContent("SNI", value: reality.serverName)
                    LabeledContent("Fingerprint", value: reality.fingerprint)
                    LabeledContent("Short ID", value: reality.shortId)
                }
            }

            Section {
                Button("Удалить сервер", role: .destructive) {
                    showingDeleteAlert = true
                }
                .frame(maxWidth: .infinity)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(config.name)
        .navigationBarTitleDisplayMode(.inline)
        .alert("Удалить сервер?", isPresented: $showingDeleteAlert) {
            Button("Удалить", role: .destructive) {
                onDelete()
                dismiss()
            }
            Button("Отмена", role: .cancel) {}
        } message: {
            Text(config.name)
        }
    }
}
