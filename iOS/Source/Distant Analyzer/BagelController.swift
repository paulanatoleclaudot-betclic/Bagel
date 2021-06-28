//
//  BagelController.swift
//  
//
//  Created by pac on 23/06/2021.
//

import Foundation

class BagelController {
    private let queue = DispatchQueue.init(label: "com.bagel.sendpacket")
    var configuration: BagelConfiguration?
    let browser: BagelBrowser
    public let ignoredURL: [String]

    init(configuration: BagelConfiguration, ignoredURL: [String]) {
        self.configuration = configuration
        self.ignoredURL = ignoredURL
        self.browser = BagelBrowser(configuration: configuration)
    }

    public func traceRequest(carrier: BagelRequestCarrier) {
        queue.async { [weak self] in
            guard let configuration = self?.configuration else { return }
            let packet = carrier.packet(configuration: configuration)
            self?.browser.sendPacket(packet: packet)
        }
    }
}
