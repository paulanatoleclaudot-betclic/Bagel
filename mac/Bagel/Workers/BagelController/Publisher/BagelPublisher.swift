//
//  BagelPublisher.swift
//  Bagel
//
//  Created by Yagiz Gurgul on 26.09.2018.
//  Copyright © 2018 Yagiz Lab. All rights reserved.
//

import Cocoa
import Starscream

protocol BagelPublisherDelegate {
    
    func didGetPacket(publisher: BagelPublisher, packet: BagelPacket)
}

class BagelPublisher: NSObject {

    var delegate: BagelPublisherDelegate?
    
    var mainSocketServer: WebSocketServer?
    var netService: NetService!
    
    func startPublishing() {
        self.mainSocketServer = WebSocketServer()
        _ = mainSocketServer?.start(address: "http://127.0.0.1", port: UInt16(BagelConfiguration.netServicePort))

        mainSocketServer?.onEvent = { [weak self] event in
            switch event {
            case let .binary(_, d):
                self?.parseBody(data: d)
            default:
                print(event)
            }
        }
        self.netService = NetService(domain: BagelConfiguration.netServiceDomain, type: BagelConfiguration.netServiceType, name: BagelConfiguration.netServiceName, port: BagelConfiguration.netServicePort)
        self.netService.delegate = self
        self.netService.publish()
    }
    
    func parseBody(data: Data) {
        
        let jsonDecoder = JSONDecoder()
        jsonDecoder.dateDecodingStrategy = .secondsSince1970
        do {
            let bagelPacket = try jsonDecoder.decode(BagelPacket.self, from: data)
            DispatchQueue.main.async {
                self.delegate?.didGetPacket(publisher: self, packet: bagelPacket)
            }
        } catch {
            print(error)
        }
    }
}


extension BagelPublisher: NetServiceDelegate {
    func netServiceDidPublish(_ sender: NetService) {
        print("publish", sender)
    }
    
    func netService(_ sender: NetService, didNotPublish errorDict: [String : NSNumber]) {
        print("error", errorDict)
    }
}


extension BagelPublisher {
    func tryPublishAgain() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.startPublishing()
        }
        
    }
}
