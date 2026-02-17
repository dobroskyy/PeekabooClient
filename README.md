# PeekabooClient

iOS VPN-клиент на базе VLESS/Reality протокола с поддержкой Xray-core.

## Стек

- Swift, UIKit
- NetworkExtension (PacketTunnelProvider)
- LibXray + Tun2SocksKit
- Keychain для хранения конфигураций

## Возможности

- Подключение по VLESS/Reality через импорт URL
- Управление несколькими серверными конфигурациями
- Мониторинг трафика в реальном времени (upload/download)

## Архитектура

Проект построен по **Clean Architecture** с разделением на слои:

```
Domain      — сущности, протоколы, use cases (бизнес-логика)
Data        — VPNService, репозитории (Config, Statistics), Keychain
Presentation — ViewController + VPNViewModel (MVVM)
Core        — DependencyContainer (ручной DI)
```

Взаимодействие между слоями строго через протоколы. `DependencyContainer` собирает граф зависимостей и передаёт их через инициализаторы.

Туннель реализован как отдельный таргет `PacketTunnelExtension`, который запускается системой в изолированном процессе. Обмен данными между приложением и расширением — через App Group (shared `UserDefaults` и файловая система).
