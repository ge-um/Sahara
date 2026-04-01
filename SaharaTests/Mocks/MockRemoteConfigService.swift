//
//  MockRemoteConfigService.swift
//  SaharaTests
//

@testable import Sahara

final class MockRemoteConfigService: RemoteConfigServiceProtocol {
    var variant: DefaultThemeVariant = .gradient

    func fetchDefaultThemeVariant() -> DefaultThemeVariant {
        return variant
    }
}
