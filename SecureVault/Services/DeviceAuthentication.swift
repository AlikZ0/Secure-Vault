import Foundation
import LocalAuthentication

/// Drives the single system authentication prompt and determines the appropriate UI.
enum DeviceAuthentication {
    enum Method {
        case faceID
        case touchID
        case passcode

        var symbol: String {
            switch self {
            case .faceID: return "faceid"
            case .touchID: return "touchid"
            case .passcode: return "lock.fill"
            }
        }

        var buttonTitle: String {
            switch self {
            case .faceID: return "Разблокировать с Face ID"
            case .touchID: return "Разблокировать с Touch ID"
            case .passcode: return "Разблокировать кодом iPhone"
            }
        }

        var detail: String {
            switch self {
            case .faceID: return "Если Face ID недоступен, iOS предложит код-пароль."
            case .touchID: return "Приложите палец к датчику Touch ID. Доступен код-пароль."
            case .passcode: return "Для входа используется код-пароль вашего устройства."
            }
        }
    }

    static func method() -> Method {
        let context = LAContext()
        // `biometryType` is only populated after querying the biometric policy.
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) else {
            return .passcode
        }
        switch context.biometryType {
        case .faceID: return .faceID
        case .touchID: return .touchID
        default: return .passcode
        }
    }

    static func authenticate(using context: LAContext) async throws {
        context.localizedFallbackTitle = "Использовать код-пароль"
        context.localizedCancelTitle = "Отмена"
        var checkError: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &checkError) else {
            throw checkError ?? AuthenticationError.unavailable
        }
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: "Подтвердите доступ к зашифрованному хранилищу"
            ) { approved, error in
                if approved {
                    continuation.resume(returning: ())
                } else {
                    continuation.resume(throwing: error ?? AuthenticationError.denied)
                }
            }
        }
    }

    static func isUserCancellation(_ error: Error) -> Bool {
        let nsError = error as NSError
        guard nsError.domain == LAErrorDomain else { return false }
        return [LAError.userCancel, LAError.systemCancel, LAError.appCancel]
            .contains { $0.rawValue == nsError.code }
    }

    static func message(for error: Error) -> String {
        let nsError = error as NSError
        if nsError.domain == LAErrorDomain {
            if nsError.code == LAError.passcodeNotSet.rawValue {
                return "Установите код-пароль iPhone в настройках устройства."
            }
            if nsError.code == LAError.biometryLockout.rawValue {
                return "Биометрия временно заблокирована. Разблокируйте устройство кодом-паролем."
            }
            if nsError.code == LAError.authenticationFailed.rawValue {
                return "Не удалось подтвердить личность. Повторите попытку."
            }
        }
        return error.localizedDescription
    }

    private enum AuthenticationError: LocalizedError {
        case unavailable
        case denied

        var errorDescription: String? {
            switch self {
            case .unavailable: return "Включите код-пароль устройства для защиты хранилища."
            case .denied: return "Проверка личности не пройдена."
            }
        }
    }
}
