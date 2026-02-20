import SwiftUI

struct VPNMainView: View {

    @ObservedObject var viewModel: VPNViewModel
    @State private var isServersExpanded = true

    var body: some View {
        NavigationView {
            List {
                Section {
                    TimelineView(.periodic(from: .now, by: 1)) { context in
                        Text(viewModel.formattedDuration(at: context.date))
                            .font(.system(size: 48, weight: .light, design: .monospaced))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    }
                    .listRowSeparator(.hidden)
                }

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

                Section {
                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            isServersExpanded.toggle()
                        }
                    } label: {
                        HStack {
                            Text("Серверы")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .foregroundColor(.secondary)
                                .rotationEffect(.degrees(isServersExpanded ? 180 : 0))
                        }
                    }
                    
                    if isServersExpanded {
                        ForEach(viewModel.configurations, id: \.id) { config in
                            let isActive = config.id == viewModel.activeConfigurationId
                            VStack(alignment: .leading, spacing: 2) {
                                Text(config.name)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                Text(config.protocolDescription)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .listRowBackground(isActive ? Color.orange.opacity(0.15) : nil)
                            .contentShape(Rectangle())
                            .opacity(viewModel.isConfigurationSelectionEnabled || isActive ? 1 : 0.5)
                            .onTapGesture {
                                if !isActive {
                                    viewModel.selectConfiguration(config.id)
                                }
                            }
                        }
                        .onDelete { indexSet in
                            indexSet.forEach { i in
                                viewModel.deleteConfiguration(id: viewModel.configurations[i].id)
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Peekaboo")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
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
                Button("OK") {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }


}

#Preview {
    VPNMainView(viewModel: DependencyContainer.shared.makeVPNViewModel())
}

