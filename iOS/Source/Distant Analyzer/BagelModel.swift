//
//  BagelModel.swift
//  
//
//  Created by pac on 23/06/2021.
//

import Foundation
import UIKit

public class BagelConfiguration {
    public var project: BagelProjectModel
    public var device: BagelDeviceModel

    public var netservicePort: Int = 43435
    public var netserviceType: String = "_Bagel._tcp"
    public var netserviceDomain: String = ""
    public var netserviceName: String = ""

    public init() {
        self.project = BagelProjectModel(projectName: BagelUtility.projectName)
        self.device = BagelDeviceModel(deviceId: BagelUtility.deviceId,
                                       deviceName: BagelUtility.deviceName,
                                       deviceDescription: BagelUtility.deviceDescription)
    }
}

public struct BagelDeviceModel {
    public var deviceId: String?
    public var deviceName: String?
    public var deviceDescription: String?
}

extension BagelDeviceModel: Codable {
    enum CodingKeys: String, CodingKey {
        case deviceId
        case deviceName
        case deviceDescription
    }
}

public struct BagelProjectModel {
    public var projectName: String?
}

extension BagelProjectModel: Codable {
    enum CodingKeys: String, CodingKey {
        case projectName
    }
}

public class BagelUtility {
    static var UUID: String {
        return NSUUID().uuidString
    }

    static var projectName: String {
        return Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
    }

    static var deviceId: String {
        return "\(self.deviceName)-\(self.deviceDescription)"
    }

    static var deviceName: String {
        return UIDevice.current.name
    }

    static var deviceDescription: String {
        return "\(UIDevice.current.model) \(UIDevice.current.systemName) \(UIDevice.current.systemVersion)"
    }
}

public struct BagelRequestInfo {
    let url: URL?
    let requestHeaders: [String: String]?
    let requestBody: Data?
    let requestMethod: String?
    let responseHeaders: [String: String]?
    let responseData: Data?
    let statusCode: String?
    let startDate: Date?
    let endDate: Date?
}

extension BagelRequestInfo: Codable {
    enum CodingKeys: String, CodingKey {
        case url
        case requestHeaders
        case requestBody
        case requestMethod
        case responseHeaders
        case responseData
        case statusCode
        case startDate
        case endDate
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(url?.absoluteString, forKey: .url)
        try container.encode(requestHeaders, forKey: .requestHeaders)
        try container.encode(requestBody, forKey: .requestBody)
        try container.encode(requestMethod, forKey: .requestMethod)
        try container.encode(responseHeaders, forKey: .responseHeaders)
        try container.encode(responseData, forKey: .responseData)
        try container.encode(statusCode, forKey: .statusCode)
        try container.encode(startDate?.timeIntervalSince1970, forKey: .startDate)
        try container.encode(endDate?.timeIntervalSince1970, forKey: .endDate)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let urlString = try? container.decode(String.self, forKey: .url) {
            url = URL(string: urlString)
        } else {
            url = nil
        }
        if let requestH = try? container.decode([String: String]?.self, forKey: .requestHeaders) {
            requestHeaders = requestH
        } else {
            requestHeaders = nil
        }
        if let requestB = try? container.decode(Data.self, forKey: .requestBody) {
            requestBody = requestB
        } else {
            requestBody = nil
        }
        if let requestM = try? container.decode(String.self, forKey: .requestMethod) {
            requestMethod = requestM
        } else {
            requestMethod = nil
        }
        if let responseH = try? container.decode([String: String]?.self, forKey: .responseHeaders) {
            responseHeaders = responseH
        } else {
            responseHeaders = nil
        }
        if let responseB = try? container.decode(Data.self, forKey: .responseData) {
            responseData = responseB
        } else {
            responseData = nil
        }
        if let statusC = try? container.decode(String.self, forKey: .statusCode) {
            statusCode = statusC
        } else {
            statusCode = nil
        }
        if let startD = try? container.decode(Double.self, forKey: .startDate) {
            startDate = Date(timeIntervalSince1970: startD)
        } else {
            startDate = nil
        }
        if let endD = try? container.decode(Double.self, forKey: .endDate) {
            endDate = Date(timeIntervalSince1970: endD)
        } else {
            endDate = nil
        }
    }
}

public struct BagelRequestPacket {
    let packetId: String?
    let requestInfo: BagelRequestInfo?
    let project: BagelProjectModel?
    let device: BagelDeviceModel?
}

extension BagelRequestPacket: Codable {
    enum CodingKeys: String, CodingKey {
        case packetId
        case requestInfo
        case project
        case device
    }
}

public class BagelRequestCarrier {
    var request: URLRequest?

    var carrierId: String?
    var response: URLResponse?

    var startDate: Date?
    var endDate: Date?

    var data: Data?
    var error: NSError?

    var isCompleted: Bool = false

    func update(urlRequest: URLRequest) {
        carrierId = BagelUtility.UUID
        request = urlRequest
        startDate = Date()
        isCompleted = false
    }

    func update(body: Data) {
        if var d = self.data {
            d.append(body)
        } else {
            self.data = body
        }
    }

    func endWithError() {
        endDate = Date()
        isCompleted = true
    }

    func updateResponse(response: URLResponse) {
        self.response = response
    }

    func endWithResponse(response: URLResponse, data: Data) {
        self.response = response
        self.data = data
        endDate = Date()
        isCompleted = true
    }

    func packet(configuration: BagelConfiguration) -> BagelRequestPacket {
        let packetId = self.carrierId



        let requestInfos = BagelRequestInfo(url: request?.url,
                                            requestHeaders: request?.allHTTPHeaderFields,
                                            requestBody: request?.httpBody,
                                            requestMethod: request?.httpMethod,
                                            responseHeaders: (response as? HTTPURLResponse)?.allHeaderFields as? [String: String],
                                            responseData: isCompleted ? data : nil,
                                            statusCode: "\((response as? HTTPURLResponse)?.statusCode ?? 0)",
                                            startDate: startDate,
                                            endDate: endDate)
        return BagelRequestPacket(packetId: packetId,
                                  requestInfo: requestInfos,
                                  project: configuration.project,
                                  device: configuration.device)
    }
}
