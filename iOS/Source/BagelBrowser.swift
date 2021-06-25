//
//  File.swift
//  
//
//  Created by pac on 23/06/2021.
//

import Foundation
import Starscream

class BagelBrowser: NSObject, NetServiceDelegate, NetServiceBrowserDelegate, WebSocketDelegate {
    let configuration: BagelConfiguration
    var services: [NetService] = []
    var sockets: [WebSocket] = []
    var serviceBrowser: NetServiceBrowser?

    required init(configuration: BagelConfiguration) {
        self.configuration = configuration
        super.init()
        startBrowsing()
    }

    private func startBrowsing() {
        services.removeAll()
        sockets.forEach { $0.disconnect() }
        sockets.removeAll()
        serviceBrowser = NetServiceBrowser()
        serviceBrowser?.delegate = self
        serviceBrowser?.searchForServices(ofType: configuration.netserviceType, inDomain: configuration.netserviceDomain)
    }

    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        services.append(service)
        service.delegate = self
        service.resolve(withTimeout: 30.0)
    }

    func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: NetService, moreComing: Bool) {
        if let index = services.firstIndex(where: { $0 == service }) {
            services.remove(at: index)
        }
    }

    func netServiceDidResolveAddress(_ sender: NetService) {
        connectWithService(service: sender)
    }

    func netServiceBrowserDidStopSearch(_ browser: NetServiceBrowser) {
        resetAndBrowse()
    }

    private func connectWithService(service: NetService) {
        guard let addresses = service.addresses else { return }
        guard let address = address(data: addresses), let url = URL(string: "ws://\(address):\(configuration.netservicePort)") else { return }
        let socket = WebSocket(request: URLRequest(url: url))
        socket.delegate = self
        socket.connect()
        sockets.append(socket)
    }

    private func resetAndBrowse() {
        serviceBrowser?.stop()
        serviceBrowser = nil

        startBrowsing()
    }

    private func address(data: [Data]) -> String? {
        var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
        guard let data = data.first else { return nil }
        data.withUnsafeBytes { ptr in
            guard let sockaddr_ptr = ptr.baseAddress?.assumingMemoryBound(to: sockaddr.self) else {
                // handle error
                return
            }
            let sockaddr = sockaddr_ptr.pointee
            guard getnameinfo(sockaddr_ptr, socklen_t(sockaddr.sa_len), &hostname, socklen_t(hostname.count), nil, 0, NI_NUMERICHOST) == 0 else {
                return
            }
        }
        return String(cString:hostname)
    }

    func didReceive(event: WebSocketEvent, client: WebSocket) {
        switch event {
        case .disconnected:
            client.delegate = nil
            removeSocket(socket: client)
        default:
            return
        }
    }

    private func removeSocket(socket: WebSocket) {
        if let index = sockets.firstIndex(where: { $0 === socket }) {
            sockets.remove(at: index)
        }
    }

    public func sendPacket(packet: BagelRequestPacket) {
        if let jsonData = try? JSONEncoder().encode(packet) {
            sockets.forEach { $0.write(data: jsonData, completion: nil) }
        }
    }
}
