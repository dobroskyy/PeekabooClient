//
//  ViewController.swift
//  PeekabooClient
//
//  Presentation Layer - View Controller
//

import UIKit
import Combine

final class ViewController: UIViewController {
    
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 16)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let serverLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 14)
        label.textColor = .gray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let statisticsLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 14)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let connectButton: UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .medium)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let addServerButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Добавить сервер из буфера", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .regular)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let tableView: UITableView = {
        let table = UITableView()
        table.translatesAutoresizingMaskIntoConstraints = false
        table.register(UITableViewCell.self, forCellReuseIdentifier: "ConfigCell")
        return table
    }()
    
    private let viewModel: VPNViewModel
    private var cancellables = Set<AnyCancellable>()
    
    init(viewModel: VPNViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        
        setupUI()
        setupConstraints()
        setupBindings()
        setupActions()
    }

    private func setupUI() {
        view.addSubview(statusLabel)
        view.addSubview(serverLabel)
        view.addSubview(statisticsLabel)
        view.addSubview(connectButton)
        view.addSubview(addServerButton)
        view.addSubview(tableView)
        
        tableView.delegate = self
        tableView.dataSource = self
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            statusLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -100),
            
            serverLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            serverLabel.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 16),
            
            statisticsLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            statisticsLabel.topAnchor.constraint(equalTo: serverLabel.bottomAnchor, constant: 16),
            
            connectButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            connectButton.topAnchor.constraint(equalTo: statisticsLabel.bottomAnchor, constant: 40),
            connectButton.widthAnchor.constraint(equalToConstant: 200),
            connectButton.heightAnchor.constraint(equalToConstant: 50),
            
            addServerButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            addServerButton.topAnchor.constraint(equalTo: connectButton.bottomAnchor, constant: 20),
            
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.topAnchor.constraint(equalTo: addServerButton.bottomAnchor, constant: 20),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    private func setupActions() {
        connectButton.addTarget(self, action: #selector(connectButtonTapped), for: .touchUpInside)
        addServerButton.addTarget(self, action: #selector(addServerButtonTapped), for: .touchUpInside)
    }

    @objc private func connectButtonTapped() {
        viewModel.toggleConnection()
    }
    
    @objc private func addServerButtonTapped() {
        guard let clipboardString = UIPasteboard.general.string else {
            showAlert(title: "Ошибка", message: "Буфер обмена пуст")
            return
        }
        
        guard clipboardString.hasPrefix("vless://") else {
            showAlert(title: "Ошибка", message: "В буфере обмена нет VLESS URL")
            return
        }
        
        viewModel.addConfiguration(from: clipboardString)
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func setupBindings() {
        
        viewModel.$status
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.statusLabel.text = status.displayText
            }
            .store(in: &cancellables)
        
        viewModel.$status
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                guard let self = self else { return }
                self.connectButton.setTitle(self.viewModel.buttonTitle, for: .normal)
                self.connectButton.isEnabled = self.viewModel.isButtonEnabled
            }
            .store(in: &cancellables)
        
        viewModel.$statistics
            .receive(on: DispatchQueue.main)
            .sink { [weak self] stats in
                self?.statisticsLabel.text = stats.displayText
            }
            .store(in: &cancellables)
        
        viewModel.$serverInfo
            .receive(on: DispatchQueue.main)
            .sink { [weak self] info in
                self?.serverLabel.text = info
            }
            .store(in: &cancellables)
        
        viewModel.$configurations
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.tableView.reloadData()
            }
            .store(in: &cancellables)
    }
}

extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.configurations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ConfigCell", for: indexPath)
        let config = viewModel.configurations[indexPath.row]
        cell.textLabel?.text = config.name
        cell.detailTextLabel?.text = "\(config.serverAddress):\(config.serverPort)"
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let config = viewModel.configurations[indexPath.row]
            viewModel.deleteConfiguration(id: config.id)
        }
    }
}

extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let config = viewModel.configurations[indexPath.row]
        viewModel.selectConfiguration(config.id)
    }
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if indexPath == tableView.indexPathForSelectedRow {
            return nil
        }
        return indexPath
    }
}


