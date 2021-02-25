////  LoginViewModel.swift
////  DigitalBank
////
////  Created by Zhalgas Baibatyr on 15/06/2018.
////  Copyright © 2018 iosDeveloper. All rights reserved.
////
//
//import Foundation
//import Alamofire
//
//class LoginViewModel {
//
//    private var authFactors: [[Constants.FactorsType]]?
//    private var parameters: Parameters = ["user_type" : "customer" ]
//    private var customers: [Customer]?
//
//    private var request: DataRequest? {
//        willSet {
//            request?.cancel()
//        }
//    }
//
//    func getAuthAccessToken(with model: LoginOAuthModel, onCompletion perform: @escaping (_ success: Bool, _ values: [String]?, _ errorMessage: String?) -> Void
//        ) {
//        request = sessionManager.request(
//            model.url,
//            method: .post,
//            parameters: model.parameters,
//            headers: model.header
//        ).validate().responseJSON { [weak self] dataResponse in
//            guard let viewModel = self else {
//                return
//            }
//            log(serverResponse: dataResponse)
//            switch dataResponse.result {
//            case .success:
//                guard let dictionary = dataResponse.result.value as? [String: Any],
//                    let model = AuthObject(JSON: dictionary) else {
//                        perform(false, nil, contentErrorMessage)
//                        return
//                }
//                viewModel.storeData(model)
//                // Pass company names in callback function
//                if let _ = model.customerId, let authFactors = viewModel.authFactors {
//                    let values = viewModel.extractAuthFactorTitles(values: authFactors)
//                    perform(true, values, nil)
//                } else {
//                    let companyNames = viewModel.customers?.compactMap { $0.name }
//                    perform(true, companyNames, nil)
//                }
//            case .failure(let error):
//                if let data = dataResponse.data,
//                   let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
//                   let errorMessage = dict["error_description"] as? String {
//                    perform(false, nil, errorMessage)
//                } else if let statusCode = dataResponse.response?.statusCode,
//                    let message = statusDescription[String(statusCode)] {
//                    perform(false, nil, message)
//                } else {
//                    perform(false, nil, error.localizedDescription)
//                }
//            }
//        }
//    }
//
//    func storeData(_ model: AuthObject) {
//
//        if let customers = model.customers {
//            self.customers = customers.filter { $0.id != nil && $0.name != nil }
//            AuthorizationAdapter.shared.customers = self.customers
//        }
//
//        // Save chosen customer id
//        if let customerUserId = model.customerUserId {
//            AuthorizationAdapter.shared.customerPersonId = customerUserId
//        }
//
//        if let passedAuthFactor = model.passedAuthFactors?.last {
//            AuthorizationAdapter.shared.lastAuthFactor = passedAuthFactor
//            // Store auth bearer token
//            if let adapter = sessionManager.adapter as? AppRequestAdapter,
//                let accessToken = model.accessToken, let refreshToken = model.refreshToken {
//                adapter.accessToken = accessToken
//                adapter.refreshToken = refreshToken
//            }
//        }
//
//        if let factorTitles = model.possibleChains {
//            let authFactors = factorTitles.map { $0.map {Constants.FactorsType(rawValue: $0)}} as? [[Constants.FactorsType]]
//            self.authFactors = authFactors ?? [[]]
//            AuthorizationAdapter.shared.authFactors = authFactors ?? [[]]
//        }
//
//        if let canSkip = model.canSkip {
//            AuthorizationAdapter.shared.canSkip = canSkip
//        }
//    }
//
//    func extractAuthFactorTitles(values: [[Constants.FactorsType]]) -> [String] {
//        return values.compactMap { value -> String in
//            let ch = value.filter { $0.rawValue != AuthorizationAdapter.shared.lastAuthFactor }.map{ $0.localized }.filter { $0.trim().count > 0 }.joined(separator: " + ")
//            return ch
//        }
//    }
//
//    /// Request available auth factors for company with provided id
//    ///
//    /// - Parameters:
//    ///   - index: company index
//    ///   - perform: on completion callback
//    func requestAuthFactorsForCompany(at index: Int, onCompletion perform: @escaping (_ success: Bool, _ errorMessage: String?) -> Void) {
//        // Check if index is appliable
//        guard let customers = customers, customers.count > index,
//              let customerPersonId = customers[index].id else {
//            perform(false, contentErrorMessage)
//            return
//        }
//
//        let apiProcessAuthFactorChooseCompanyUrl = baseURL + "/api/process-auth-factor/choose-company"
//        let parameters = ["companyPersonId": customerPersonId]
//
//        request = sessionManager.request(
//            apiProcessAuthFactorChooseCompanyUrl,
//            method: .post,
//            parameters: parameters,
//            encoding: JSONEncoding.default
//        ).validate().responseJSON { dataResponse in
//            log(serverResponse: dataResponse)
//            switch dataResponse.result {
//            case .success:
//                // Check if response contains data
//                guard let dictionary = dataResponse.result.value as? [String: Any],
//                    let authFactorResponse = AuthFactorResponse(JSON: dictionary) else {
//                    perform(false, contentErrorMessage)
//                    return
//                }
//
//                // Save chosen company id
//                AuthorizationAdapter.shared.customerPersonId = customerPersonId
//                // Save auth factors
//                AuthorizationAdapter.shared.authFactorResponse = authFactorResponse
//
//                perform(true, nil)
//
//            case .failure(let error):
//                if let data = dataResponse.data,
//                   let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
//                   let errorMessage = dict["errorMessage"] as? String {
//                    perform(false, errorMessage)
//                } else if let statusCode = dataResponse.response?.statusCode,
//                    let message = statusDescription[String(statusCode)] {
//                    perform(false, message)
//                } else {
//                    perform(false, error.localizedDescription)
//                }
//            }
//        }
//    }
//
//    func skipCurrentAuthFactor(onCompletion perform: @escaping (_ success: Bool, _ errorMessage: String?) -> Void) {
//        let apiProcessAuthFactorConfirmUrl = baseURL + "/api/process-auth-factor/confirm"
//        request = sessionManager.request(
//            apiProcessAuthFactorConfirmUrl,
//            method: .post,
//            parameters: ["companyPersonId": AuthorizationAdapter.shared.customerPersonId as Any],
//            encoding: JSONEncoding.default
//        ).validate().responseJSON { dataResponse in
//            log(serverResponse: dataResponse)
//            switch dataResponse.result {
//            case .success:
//                perform(true, nil)
//            case .failure(let error):
//                if let data = dataResponse.data,
//                   let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
//                   let errorMessage = dict["errorMessage"] as? String {
//                    perform(false, errorMessage)
//                } else if let statusCode = dataResponse.response?.statusCode,
//                    let message = statusDescription[String(statusCode)] {
//                    perform(false, message)
//                } else {
//                    perform(false, error.localizedDescription)
//                }
//            }
//        }
//    }
//}
