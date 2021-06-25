//
//  BagelAuthenticationChallengeSender.swift
//  
//
//  Created by pac on 24/06/2021.
//

import Foundation

class BagelAuthenticationChallengeSender : NSObject, URLAuthenticationChallengeSender {

    typealias NFXAuthenticationChallengeHandler = (URLSession.AuthChallengeDisposition, URLCredential?) -> Void

    let handler: NFXAuthenticationChallengeHandler

    init(handler: @escaping NFXAuthenticationChallengeHandler) {
        self.handler = handler
        super.init()
    }

    func use(_ credential: URLCredential, for challenge: URLAuthenticationChallenge) {
        handler(.useCredential, credential)
    }

    func continueWithoutCredential(for challenge: URLAuthenticationChallenge) {
        handler(.useCredential, nil)
    }

    func cancel(_ challenge: URLAuthenticationChallenge) {
        handler(.cancelAuthenticationChallenge, nil)
    }

    func performDefaultHandling(for challenge: URLAuthenticationChallenge) {
        handler(.performDefaultHandling, nil)
    }

    func rejectProtectionSpaceAndContinue(with challenge: URLAuthenticationChallenge) {
        handler(.rejectProtectionSpace, nil)
    }
}
