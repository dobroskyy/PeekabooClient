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
            connectButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    private func setupActions() {
        connectButton.addTarget(self, action: #selector(connectButtonTapped), for: .touchUpInside)
    }

    @objc private func connectButtonTapped() {
        viewModel.toggleConnection()
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
    }
}


