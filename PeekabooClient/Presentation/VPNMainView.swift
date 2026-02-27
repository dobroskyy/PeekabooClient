import SwiftUI

struct VPNMainView: View {

    @StateObject var viewModel: VPNViewModel
    @State private var isServersExpanded = true

    var body: some View {
        NavigationStack {
            List {
                durationSection
                connectionToggleSection
                serversSection
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Peekaboo")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.addConfigurationFromClipboard()
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .alert("Ошибка", isPresented: Binding(
                get: { viewModel.showError },
                set: { _ in viewModel.clearError() }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }

    private var durationSection: some View {
        Section {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                Text(viewModel.formattedDuration(at: context.date))
                    .font(.system(size: UIConstants.timerFontSize, weight: .light, design: .monospaced))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, UIConstants.timerVerticalPadding)
            }
            .listRowSeparator(.hidden)
        }
        
    }

    private var connectionToggleSection: some View {
        Section {
            Toggle(isOn: Binding(
                get: { viewModel.status == .connected },
                set: { _ in viewModel.toggleConnection() }
            )) {
                Text(viewModel.buttonTitle)
            }
            .disabled(!viewModel.isButtonEnabled)
            .tint(.orange)
        
        }
        
    }

    private var serversSection: some View {
        Section {
            DisclosureGroup("Серверы", isExpanded: $isServersExpanded) {
                if viewModel.configurations.isEmpty {
                    emptyStateView
                } else {
                    ForEach(viewModel.configurations, id: \.id) { config in
                        ServerRowView(
                            configuration: config,
                            isActive: config.id == viewModel.activeConfigurationId,
                            isSelectionEnabled: viewModel.isConfigurationSelectionEnabled,
                            onSelect: {
                                if config.id != viewModel.activeConfigurationId {
                                    viewModel.selectConfiguration(config.id)
                                }
                            }
                        )
                    }
                    .onDelete(perform: deleteConfigurations)
                }
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: UIConstants.emptyStateSpacing) {
            Image(systemName: "network.slash")
                .font(.system(size: UIConstants.emptyStateIconSize))
                .foregroundStyle(.secondary)
            Text("Нет серверов")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("Нажмите + для добавления сервера из буфера обмена")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, UIConstants.emptyStateVerticalPadding)
    }

    private func deleteConfigurations(at indexSet: IndexSet) {
        indexSet.forEach { i in
            viewModel.deleteConfiguration(id: viewModel.configurations[i].id)
        }
    }
}

private struct ServerRowView: View {
    let configuration: VPNConfiguration
    let isActive: Bool
    let isSelectionEnabled: Bool
    let onSelect: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: UIConstants.serverRowSpacing) {
            Text(configuration.name)
                .lineLimit(1)
                .truncationMode(.tail)
            Text(configuration.protocolDescription)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .listRowBackground(isActive ? Color.orange.opacity(UIConstants.activeRowOpacity) : nil)
        .contentShape(Rectangle())
        .opacity(isSelectionEnabled || isActive ? 1 : UIConstants.disabledRowOpacity)
        .onTapGesture {
            if isSelectionEnabled && !isActive {
                onSelect()
            }
        }
    }
}


private enum UIConstants {
    static let timerFontSize: CGFloat = 48
    static let timerVerticalPadding: CGFloat = 16
    static let serverRowSpacing: CGFloat = 2
    static let activeRowOpacity: CGFloat = 0.15
    static let disabledRowOpacity: CGFloat = 0.5
    static let emptyStateIconSize: CGFloat = 48
    static let emptyStateSpacing: CGFloat = 8
    static let emptyStateVerticalPadding: CGFloat = 32
}


#Preview {
    VPNMainView(viewModel: DependencyContainer.shared.makeVPNViewModel())
}

