# Secure Vault + Clipboard Cleaner

Нативное iOS-приложение на SwiftUI, рассчитанное на iOS 17+. Работает локально, без регистрации, сервера и сторонних библиотек. Проект можно собирать **без Mac** через GitHub Actions, но полученный IPA **не подписан**: перед установкой на iPhone его необходимо подписать под своё устройство.

## Что реализовано

- Добавление, редактирование, удаление и поиск логинов/паролей/заметок.
- Шифрование **всего** JSON-хранилища (включая названия и логины) через CryptoKit AES-256-GCM.
- Разблокировка с немедленным системным запросом Face ID / Touch ID / кода устройства, автоматическая попытка после запуска и при возвращении из фона; отмена не вызывает навязчивую ошибку.
- Значок приложения явно указывается через AppIcon в asset catalog; GitHub Actions проверяет его наличие в собранной .app. Добавлен фирменный launch screen.
- Ключ AES-256 лежит в Keychain с `kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly` и `.userPresence`: подтверждение Face ID/Touch ID или кодом устройства на доступ к ключу.
- Ключ создаётся один раз, существующий ключ никогда не перезаписывается автоматически.
- При сворачивании приложения текущий экран блокируется, ссылка на ключ и список записей очищаются из состояния приложения; при неактивном окне показывается экран-заглушка.
- Генератор паролей 12–64 символа с `SystemRandomNumberGenerator` и минимум одним символом каждой категории.
- Копирование пароля/логина с `localOnly=true` и **системным** сроком действия 60 секунд; ручная очистка не удаляет данные, если буфер уже изменился.
- Светлая/тёмная тема по настройке iOS.
- XCTest: обратимость шифрования, неверный ключ, повреждённый шифртекст, генератор.

### Что намеренно не реализовано

- Чтение буфера обмена других приложений и постоянная работа в фоне: iOS не даёт обычным приложениям универсального доступа к этому.
- Синхронизация между устройствами, облачные бэкапы, импорт/экспорт ключа, восстановление данных и автозаполнение паролей в других приложениях.
- Заявление об аудированной/сертифицированной безопасности: MVP **не проходил независимый security audit**.

## Установка/сборка с Ubuntu без Mac

### 1. Создать репозиторий

1. Распакуй ZIP-архив.
2. На [github.com/new](https://github.com/new) создай **приватный** репозиторий, например `SecureVault`.
3. Открой терминал в папке, где находится `project.yml`, и выполни:

```bash
git init -b main
git add .
git commit -m "Initial Secure Vault iOS MVP"
git remote add origin https://github.com/YOUR_USERNAME/SecureVault.git
git push -u origin main
```

Заменить `YOUR_USERNAME` на свой логин GitHub. Авторизацию GitHub настрой через SSH или Personal Access Token (пароль аккаунта для HTTPS push обычно не подходит).

### 2. Собрать unsigned IPA на GitHub

1. Открой свой репозиторий → вкладка **Actions**.
2. Выбери **Build Secure Vault (unsigned IPA)** → **Run workflow** → **Run workflow**.
3. Открой завершившийся запуск → секция **Artifacts**.
4. Скачай **SecureVault-unsigned-IPA**, распакуй архив артефакта и получи файл `SecureVault-unsigned.ipa`.

GitHub Actions запускает macOS, устанавливает `xcodegen`, генерирует `.xcodeproj`, собирает `.app` для iPhone без подписи и упаковывает его в IPA. Самостоятельная сборка Xcode-проекта из Ubuntu без macOS SDK здесь **не предусмотрена**.

Файл процесса сборки: `.github/workflows/main.yml`. Исходный проект Xcode описан в `project.yml`.

### 3. Установить на iPhone

**IPA из GitHub не устанавливается напрямую**, поскольку он unsigned. Нужна подпись Apple ID для твоего устройства. На Linux можно попробовать [Apparition](https://github.com/illixion/Apparition) (предусмотрена Linux CLI):

1. Скачай Linux-сборку из [официальных релизов Apparition](https://github.com/illixion/Apparition/releases), распакуй и установи по инструкции автора; проверь команду `apparition --version`.
2. Подключи iPhone к Ubuntu через USB, разблокируй его и подтверди **«Доверять этому компьютеру»**.
3. В терминале выполни (Apparition должен быть в `PATH`):

```bash
apparition pair --usb
apparition install /path/to/SecureVault-unsigned.ipa --apple-id your-apple-id@example.com
```

4. Войди в **свой** Apple ID в интерфейсе инструмента, пройди двухфакторную проверку, если появится запрос.
5. На iPhone при необходимости открой **Настройки → Основные → VPN и управление устройством**, выбери профиль разработчика и подтверди доверие.
6. Если iOS запрашивает **Режим разработчика**, включи его в **Настройки → Конфиденциальность и безопасность → Режим разработчика** и перезагрузи iPhone. Иногда этот пункт становится видимым только после попытки установки/соединения с инструментами разработки.
7. На iPhone должен быть установлен **код-пароль экрана блокировки**, иначе приложение не сможет создать защищённый ключ.

Apparition — сторонний проект; процедура установки зависит от версии iOS, версии программы и состояния сервисов Apple. **Эта инструкция не означает, что установка была проверена на твоём устройстве.** Не вводи Apple ID на сомнительных сайтах; устанавливай инструменты из официального репозитория.

**Бесплатная подпись:** Apple ограничивает действие provisioning profile семью днями. После этого приложение понадобится повторно подписать/обновить. Не удаляй приложение с настоящими паролями ради обновления: данные могут быть потеряны. Репозиторий и сборка не содержат твоих паролей.

## Настройка приложения

По умолчанию Bundle Identifier: `com.example.securevault.local`. Для своей постоянной установки задай свой уникальный ID в `project.yml`, **до первого подписывания**. Затем не меняй его: новая подпись/другой ID может привести к потере доступа к Keychain и данным.

Приложение не требует интернет-доступа и не добавляет сторонних SDK. В Info.plist при генерации проекта включается `NSFaceIDUsageDescription`.

## Локальная сборка на Mac (не требуется для твоего сценария)

```bash
brew install xcodegen
xcodegen generate --spec project.yml
open SecureVault.xcodeproj
```

В Xcode выбери Apple Team в Signing & Capabilities и реальный iPhone. Запуск тестов: `Product → Test` в Xcode.

## Где что исправлять

| Файл | Назначение |
| --- | --- |
| `SecureVault/Models/VaultItem.swift` | Модель записи |
| `SecureVault/Services/CryptoService.swift` | AES-256-GCM |
| `SecureVault/Services/KeychainService.swift` | Главный ключ, Keychain, Face ID |
| `SecureVault/Services/VaultRepository.swift` | Зашифрованный файл и защита данных |
| `SecureVault/Services/ClipboardService.swift` | Копирование и очистка буфера |
| `SecureVault/Services/PasswordGenerator.swift` | Криптостойкая генерация |
| `SecureVault/ViewModels/VaultViewModel.swift` | Управление хранилищем |
| `SecureVault/Views/LockView.swift` | Экран входа |
| `SecureVault/Views/VaultHomeView.swift` | Главный экран и поиск |
| `SecureVault/Views/AddEditItemView.swift` | Добавление/редактирование |
| `SecureVault/Views/ItemDetailView.swift` | Просмотр, копирование, удаление |
| `SecureVault/Views/Theme.swift` | Цвета и общий UI |
| `SecureVaultTests/SecureVaultTests.swift` | Unit-тесты |
| `.github/workflows/main.yml` | Workflow сборки IPA |
| `project.yml` | Конфигурация XcodeGen |

## Ограничения безопасности и восстановление

1. Удаление приложения, сброс устройства, удаление кода-пароля iPhone или потеря master key могут сделать данные недоступными безвозвратно. Здесь **нет** резервного копирования или экспорта.
2. Keychain `ThisDeviceOnly` не переносится на другой iPhone; зашифрованный файл также исключён из резервного копирования. Для настоящих ценных паролей сначала реализуй и проверь стратегию восстановления.
3. Буфер обмена хранит скопированный пароль максимум заданное системное время, если ОС применяет срок действия; приложение не может гарантировать, что другая программа не прочитает пароль до истечения 60 секунд.
4. SwiftUI-состояние и строки с паролями могут кратковременно находиться в памяти приложения. Очистка `@Published`-массива при блокировке **не равнозначна гарантированному zeroization памяти**.
5. Не используй этот MVP как единственное место хранения критичных паролей, пока не проверены резервное копирование, восстановление и сборка на реальном устройстве.

## Источники API

- [Apple: Accessing Keychain Items with Face ID or Touch ID](https://developer.apple.com/documentation/localauthentication/accessing-keychain-items-with-face-id-or-touch-id)
- [Apple: UIPasteboard](https://developer.apple.com/documentation/uikit/uipasteboard)
- [Apple: Free developer account](https://developer.apple.com/help/account/basics/about-your-developer-account)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)
- [Apparition](https://github.com/illixion/Apparition)

## Что исправлено в версии 2

1. `SecureVault/Services/DeviceAuthentication.swift` — определение Face ID, Touch ID, отсутствия биометрии; единая системная проверка с запасным кодом устройства.
2. `SecureVault/ViewModels/VaultViewModel.swift` — мгновенная реакция кнопки, асинхронное подтверждение, чтение ключа вне главного потока, защита от устаревшего ответа после блокировки.
3. `SecureVault/Services/KeychainService.swift` — чтение ключа с уже авторизованным `LAContext`, без второго системного запроса. Идентификаторы Keychain не менялись.
4. `SecureVault/Views/LockView.swift` — правильная иконка Face ID / Touch ID и подписи, а также статус операции и ошибка прямо на экране.
5. `SecureVault/SecureVaultApp.swift` — маска приватности не перекрывает экран входа при системной биометрии.
6. `project.yml` и `Assets.xcassets` — отдельная картинка и цвет запуска, контроль наличия иконки в workflow.

**Для сохранения существующих данных:** обновляй приложение поверх старого; не удаляй его и не меняй `PRODUCT_BUNDLE_IDENTIFIER`, Apple Team/Keychain access group или способы подписи, влияющие на доступ к Keychain. Если инструмент установки всегда переустанавливает приложение с удалением данных, сначала проверь на тестовых записях.

**Проверка:** выполняется на GitHub Actions с macOS; локальная проверка на Linux не заменяет компиляцию и запуск на iPhone.
