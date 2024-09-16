//
//  ReadOnlyRPCProvider.swift
//  metamask-ios-sdk
//

import Foundation

public class ReadOnlyRPCProvider {
    let infuraAPIKey: String
    private let network: any Networking
    
    let rpcUrls: [String: String]
    let readonlyRPCMap: [String: String]
    
    public convenience init(infuraAPIKey: String? = nil, readonlyRPCMap: [String: String]? = nil) {
        self.init(infuraAPIKey: infuraAPIKey, readonlyRPCMap: readonlyRPCMap, network: Network())
    }

    init(infuraAPIKey: String? = nil, readonlyRPCMap: [String: String]?, network: any Networking) {
        self.infuraAPIKey = infuraAPIKey ?? ""
        self.network = network
        self.readonlyRPCMap = readonlyRPCMap ?? [:]
        
        if let providedRPCMap = readonlyRPCMap {
            if let apiKey = infuraAPIKey {
                // Merge infuraReadonlyRPCMap with readonlyRPCMap, overriding infura's keys if they are present in readonlyRPCMap
                var mergedMap = ReadOnlyRPCProvider.infuraReadonlyRPCMap(apiKey)
                providedRPCMap.forEach { mergedMap[$0.key] = $0.value }
                self.rpcUrls = mergedMap
            } else {
                // Use only the provided readonlyRPCMap
                self.rpcUrls = providedRPCMap
            }
        } else if let apiKey = infuraAPIKey {
            // Use infuraReadonlyRPCMap as default
            self.rpcUrls = ReadOnlyRPCProvider.infuraReadonlyRPCMap(apiKey)
        } else {
            // Default to an empty map if neither are provided
            self.rpcUrls = [:]
        }
    }
    
    func supportsChain(_ chainId: String) -> Bool {
        return rpcUrls[chainId] != nil && (readonlyRPCMap[chainId] != nil || !infuraAPIKey.isEmpty)
    }
    
    static func infuraReadonlyRPCMap(_ infuraAPIKey: String) -> [String: String] {
        [
            // ###### Ethereum ######
            // Mainnet
            "0x1": "https://mainnet.infura.io/v3/\(infuraAPIKey)",
            // Sepolia 11155111
            "0x2a": "https://sepolia.infura.io/v3/\(infuraAPIKey)",
            // ###### Polygon ######
            // Mainnet
            "0x89": "https://polygon-mainnet.infura.io/v3/\(infuraAPIKey)",
            // Mumbai
            "0x13881": "https://polygon-mumbai.infura.io/v3/\(infuraAPIKey)",
            // ###### Optimism ######
            // Mainnet
            "0x45": "https://optimism-mainnet.infura.io/v3/\(infuraAPIKey)",
            // Goerli
            "0x1a4": "https://optimism-goerli.infura.io/v3/\(infuraAPIKey)",
            // ###### Arbitrum ######
            // Mainnet
            "0xa4b1": "https://arbitrum-mainnet.infura.io/v3/\(infuraAPIKey)",
            // Goerli
            "0x66eed": "https://arbitrum-goerli.infura.io/v3/\(infuraAPIKey)",
            // ###### Palm ######
            // Mainnet
            "0x2a15c308d": "https://palm-mainnet.infura.io/v3/\(infuraAPIKey)",
            // Testnet
            "0x2a15c3083": "https://palm-testnet.infura.io/v3/\(infuraAPIKey)",
            // ###### Avalanche C-Chain ######
            // Mainnet
            "0xa86a": "https://avalanche-mainnet.infura.io/v3/\(infuraAPIKey)",
            // Fuji
            "0xa869": "https://avalanche-fuji.infura.io/v3/\(infuraAPIKey)",
            // ###### NEAR ######
            // // Mainnet
            // "0x4e454152": "https://near-mainnet.infura.io/v3/\(infuraAPIKey)",
            // // Testnet
            // "0x4e454153": "https://near-testnet.infura.io/v3/\(infuraAPIKey)",
            // ###### Aurora ######
            // Mainnet
            "0x4e454152": "https://aurora-mainnet.infura.io/v3/\(infuraAPIKey)",
            // Testnet
            "0x4e454153": "https://aurora-testnet.infura.io/v3/\(infuraAPIKey)",
            // ###### StarkNet ######
            // Mainnet
            "0x534e5f4d41494e": "https://starknet-mainnet.infura.io/v3/\(infuraAPIKey)",
            // Goerli
            "0x534e5f474f45524c49": "https://starknet-goerli.infura.io/v3/\(infuraAPIKey)",
            // Goerli 2
            "0x534e5f474f45524c4932": "https://starknet-goerli2.infura.io/v3/\(infuraAPIKey)",
            // ###### Celo ######
            // Mainnet
            "0xa4ec": "https://celo-mainnet.infura.io/v3/\(infuraAPIKey)",
            // Alfajores Testnet
            "0xaef3": "https://celo-alfajores.infura.io/v3/\(infuraAPIKey)"
        ]
    }
    
    func endpoint(for chainId: String) -> String? {
        rpcUrls[chainId]
    }

    public func sendRequest(_ request: any RPCRequest,
                            params: Any = "",
                            chainId: String,
                            appMetadata: AppMetadata) async -> Any? {

        let params: [String: Any] = [
            "method": request.method,
            "jsonrpc": "2.0",
            "id": request.id,
            "params": params
        ]

        guard let endpoint = endpoint(for: chainId) else {
            Logging.error("ReadOnlyRPCProvider:: Infura endpoint for chainId \(chainId) is not available")
            return nil
        }
        
        Logging.log("ReadOnlyRPCProvider:: Sending request \(request.method) on chain \(chainId) using endpoint \(endpoint) via Infura API")

        let devicePlatformInfo = DeviceInfo.platformDescription
        network.addHeaders([
            "Metamask-Sdk-Info": "Sdk/iOS SdkVersion/\(SDKInfo.version) Platform/\(devicePlatformInfo) dApp/\(appMetadata.url) dAppTitle/\(appMetadata.name)"
        ]
        )

        do {
            let response = try await network.post(params, endpoint: endpoint)
            let json: [String: Any] = try JSONSerialization.jsonObject(
                with: response,
                options: []
            ) as? [String: Any] ?? [:]

            if let result = json["result"] {
                return result
            }

            Logging.error("ReadOnlyRPCProvider:: could not get result from response \(json)")
            if let error = json["error"] as? [String: Any] {
                return RequestError(from: error)
            }
            
            return nil
        } catch {
            Logging.error("ReadOnlyRPCProvider:: error: \(error.localizedDescription)")
            return RequestError(from: ["code": -1, "message": error.localizedDescription])
        }
    }
}
