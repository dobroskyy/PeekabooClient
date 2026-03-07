//
//  Settings​View​Controller​.swift
//  PeekabooClient
//
//  Created by Максим on 17.02.2026.
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        List {
            Section(header: Text("О приложении")) {
                LabeledContent {
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                } label: {
                    Label("Версия приложения", systemImage: "info.circle")
                }

                LabeledContent {
                    Text(AppConstants.xrayVersion)
                } label: {
                    Label("Версия Xray", systemImage: "network")
                }
            }
        }
    }
}
#Preview {
    SettingsView()
}

