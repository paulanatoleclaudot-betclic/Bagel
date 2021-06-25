//
//  File.swift
//  
//
//  Created by pac on 24/06/2021.
//

import Foundation

@objc
open class BagelURLProtocol: URLProtocol
{
    private static let bagelInternalKey = "com.bagel.internalkey"

    private lazy var session: URLSession = { [unowned self] in
        return URLSession(configuration: .default, delegate: self, delegateQueue: nil)
    }()

    private let model = BagelRequestCarrier()
    private var response: URLResponse?
    private var responseData: NSMutableData?

    override open class func canInit(with request: URLRequest) -> Bool
    {
        return canServeRequest(request)
    }

    override open class func canInit(with task: URLSessionTask) -> Bool
    {
        guard let request = task.currentRequest else { return false }
        return canServeRequest(request)
    }

    private class func canServeRequest(_ request: URLRequest) -> Bool
    {
        guard Bagel.isEnabled else {
            return false
        }

        guard
            URLProtocol.property(forKey: BagelURLProtocol.bagelInternalKey, in: request) == nil,
            let url = request.url,
            (url.absoluteString.hasPrefix("http") || url.absoluteString.hasPrefix("https"))
        else {
            return false
        }
        let absoluteString = url.absoluteString
        guard !(Bagel.controller?.ignoredURL.contains(where: { absoluteString.hasPrefix($0) }) ?? false)  else {
            return false
        }
        
        return true
    }

    override open func startLoading()
    {
        model.update(urlRequest: request)

        let mutableRequest = (request as NSURLRequest).mutableCopy() as! NSMutableURLRequest
        URLProtocol.setProperty(true, forKey: BagelURLProtocol.bagelInternalKey, in: mutableRequest)
        session.dataTask(with: mutableRequest as URLRequest).resume()

        Bagel.controller?.traceRequest(carrier: model)
    }

    override open func stopLoading()
    {
        session.getTasksWithCompletionHandler { dataTasks, _, _ in
            dataTasks.forEach { $0.cancel() }
        }
    }

    override open class func canonicalRequest(for request: URLRequest) -> URLRequest
    {
        return request
    }
}

extension BagelURLProtocol: URLSessionDataDelegate {
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        responseData?.append(data)

        client?.urlProtocol(self, didLoad: data)
    }

    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        self.response = response
        self.responseData = NSMutableData()

        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        completionHandler(.allow)
    }

    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        defer {
            if let error = error {
                client?.urlProtocol(self, didFailWithError: error)
            } else {
                client?.urlProtocolDidFinishLoading(self)
            }
        }

        guard task.originalRequest != nil else {
            return
        }

        if error != nil {
            model.endWithError()
        } else if let response = response {
            let data = (responseData ?? NSMutableData()) as Data
            model.endWithResponse(response: response, data: data)
        }

        Bagel.controller?.traceRequest(carrier: model)
    }

    public func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {

        let updatedRequest: URLRequest
        if URLProtocol.property(forKey: BagelURLProtocol.bagelInternalKey, in: request) != nil {
            let mutableRequest = (request as NSURLRequest).mutableCopy() as! NSMutableURLRequest
            URLProtocol.removeProperty(forKey: BagelURLProtocol.bagelInternalKey, in: mutableRequest)

            updatedRequest = mutableRequest as URLRequest
        } else {
            updatedRequest = request
        }

        client?.urlProtocol(self, wasRedirectedTo: updatedRequest, redirectResponse: response)
        completionHandler(updatedRequest)
    }

    public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        let wrappedChallenge = URLAuthenticationChallenge(authenticationChallenge: challenge, sender: BagelAuthenticationChallengeSender(handler: completionHandler))
        client?.urlProtocol(self, didReceive: wrappedChallenge)
    }

    #if !os(OSX)
    public func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        client?.urlProtocolDidFinishLoading(self)
    }
    #endif
}
