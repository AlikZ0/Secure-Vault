# Установка с Ubuntu: короткая инструкция

## Шаг 1. Создай приватный репозиторий GitHub

Открой https://github.com/new, название `SecureVault`.

## Шаг 2. Загрузи исходники

```bash
cd ~/Загрузки/SecureVault_Project
git init -b main
git add .
git commit -m "Add Secure Vault"
git remote add origin https://github.com/YOUR_USERNAME/SecureVault.git
git push -u origin main
```

Заменить `YOUR_USERNAME`.

## Шаг 3. Сборка

GitHub → твой репозиторий → **Actions** → **Build Secure Vault (unsigned IPA)** → **Run workflow**.

После успешной сборки скачай Artifacts → `SecureVault-unsigned-IPA` → распакуй → `SecureVault-unsigned.ipa`.

## Шаг 4. Установка на iPhone

IPA **без цифровой подписи**. Для установки с Linux можно воспользоваться официальным репозиторием [Apparition](https://github.com/illixion/Apparition). После установки CLI и подключения доверенного iPhone по кабелю:

```bash
apparition pair --usb
apparition install ./SecureVault-unsigned.ipa --apple-id your-apple-id@example.com
```

При необходимости подтверди профиль в «Основные → VPN и управление устройством» и включи «Режим разработчика» в «Конфиденциальность и безопасность».

**Для работы хранилища обязателен код-пароль iPhone.** При бесплатной подписи требуется обновление приложения обычно каждые 7 дней. Не удаляй приложение с данными: ключ не экспортируется. См. `README.md` для технических деталей и ограничений.
