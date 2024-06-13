// Mock classes for testing

import metamask_ios_sdk

class MockNetwork: Networking {
    func post(_ parameters: [String : Any], endpoint: String) async throws -> Data {
        if let error = error {
            throw error
        }

        return responseData ?? Data()
    }
    
    var responseData: Data?
    var error: Error?
    
    func post(_ parameters: [String : Any], endpoint: Endpoint) async throws -> Data {
        if let error = error {
            throw error
        }

        return responseData ?? Data()
    }
    
    public func fetch<T: Decodable>(_ Type: T.Type, endpoint: Endpoint) async throws -> T {
        return responseData as! T
    }

        
    func addHeaders(_ headers: [String : String]) {
        
    }
}
