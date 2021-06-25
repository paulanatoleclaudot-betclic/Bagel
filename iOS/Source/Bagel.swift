//
//  Bagel.swift
//  
//
//  Created by pac on 23/06/2021.
//

import Foundation

public class Bagel {
    static var bagelVersion: String?
    static var controller: BagelController?
    static var isEnabled: Bool = false
    public static func start(configuration: BagelConfiguration = BagelConfiguration(), ignoredURL: [String] = []) {
        controller = BagelController(configuration: configuration, ignoredURL: ignoredURL)
        isEnabled = true
        URLProtocol.registerClass(BagelURLProtocol.self)
        _ = swizzleURLSession
        _ = swizzleDefaultSessionConfiguration
    }
}

let swizzleURLSession: Void = {
    let m1 = class_getClassMethod(URLSession.self, #selector(URLSession.init(configuration:)))
    let m2 = class_getClassMethod(URLSession.self, #selector(URLSession.swizzled_init(configuration:)))
    if let m1 = m1, let m2 = m2 { method_exchangeImplementations(m1, m2) }
}()

extension URLSession {
    @objc dynamic class func swizzled_init(configuration: URLSessionConfiguration) -> URLSession {
        configuration.protocolClasses = [BagelURLProtocol.self] + (configuration.protocolClasses ?? [])
        return swizzled_init(configuration: configuration)
    }
}

let swizzleDefaultSessionConfiguration: Void = {
    let m1 = class_getClassMethod(URLSessionConfiguration.self, #selector(getter: URLSessionConfiguration.default))
    let m2 = class_getClassMethod(URLSessionConfiguration.self, #selector(URLSessionConfiguration.swizzled_defaultSessionConfiguration))
    if let m1 = m1, let m2 = m2 { method_exchangeImplementations(m1, m2) }
}()

extension URLSessionConfiguration {
    @objc dynamic class func swizzled_defaultSessionConfiguration() -> URLSessionConfiguration {
        let configuration = swizzled_defaultSessionConfiguration()
        configuration.protocolClasses = [BagelURLProtocol.self] + (configuration.protocolClasses ?? [])
        return configuration
    }
}
