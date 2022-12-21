# MetaMask iOS SDK
MetaMask iOS SDK is a library that enables developers to run decentralised applications (Dapps) as native iOS applications.

## How it works
You can import the MetaMask iOS SDK into your iOS application to enable users to easily connect with their MetaMask Mobile wallet.

### 1. Install
Add MetaMask iOS SDK as a cocoapods dependency to your project 
```
  pod 'metamask-ios-sdk'
```
#### Note
Please note that the SDK currently supports the following architectures 
- `aarch64-apple-ios` (iOS devices) and 
- `x86_64-apple-ios` (Intel Mac-based simulators)

We currently do not support `aarch64-apple-ios-sim` (M1 or Apple Silicon simulators) because of an architecture support limitation we have on the cryto module we use. 

However, you should be able run iton an M1 simulator by setting your Xcode to open in Rosetta mode. This can be done by going to /Applications, right click on Xcode -> Get Info -> check the option "Open using Rosetta". This effectively runs Xcode in Intel mode.
### 2. Import the SDK
```
import metamask_ios_sdk
```

### 3. Connect your Dapp
```
@ObservedObject var ethereum = Ethereum.shared
let dappMetaData = DappMetadata(name: "myapp", url: "myapp.com")

// This is the same as calling "eth_requestAccounts"
ethereum.connect(dappMetaData)
```
### 4. You can now call any ethereum provider method
We use Combine to publish ethereum events, so you need to have a cancellables set. You can also declare an ethereum object if you prefer.
```
@ObservedObject var ethereum: Ethereum = Ethereum.shared
@State private var cancellables: Set<AnyCancellable> = []
```
#### 4.1 Get `eth_chainId`
```
@State var chainID: String?

let chainIdRequest = EthereumRequest(method: .ethChainId)

ethereum.request(chainIdRequest)?.sink(receiveCompletion: { completion in
    switch completion {
    case .failure(let error):
        print("\(error.localizedDescription)")
    default: break
    }
}, receiveValue: { chainId in
    self.chainID = chainId
})
.store(in: &cancellables)  
```

#### 4.2 Send transaction
```
// Create a transaction
let transaction = Transaction(
    to: "0x...",
    from: ethereum.selectedAddress,
    value: "0x...")
    
// Create a request
let transactionRequest = EthereumRequest(
    method: .sendTransaction,
    params: [transaction])

// Send a transaction request
ethereum.request(chainItransactionRequestdRequest)?.sink(receiveCompletion: { completion in
    switch completion {
    case .failure(let error):
        print("\(error.localizedDescription)")
    default: break
    }
}, receiveValue: { result in
    print(result)
})
.store(in: &cancellables)  
```

#### 4.2 Custom requests
To create your own requests, you can use a primitive key-pair data type dictionary object or use a struct that conforms to `CodableData` i.e implementing the `func socketRepresentation() -> NetworkData` requirement, so that the type can be represented as a socket packet.
```
let params: [String: String] = [
    "to": "0x...",
    "from": "ethereum.selectedAddress",
    "value": "0x..."
  ]
  
let request = EthereumRequest(
    method: .sendTransaction,
    params: [params])

ethereum.request(request)
```
OR
```
public struct MyStruct: CodableData {
    public var to: String
    public let from: String
    public var value: String
    
    public init(to: String, from: String, value: String) {
        self.to = to
        self.from = from
        self.value = value
    }
    
    public func socketRepresentation() -> NetworkData {
        [
            "to": to,
            "from": from,
            "value": value
        ]
    }
}
// Then use struct object as shown in 4.2 above
```


## Example
We have created an [Example](./Example/) project as a guide on how to connect to ethereum and make requests.
To run the example project, clone this repository, change directory to `metamask-ios-sdk/Example`, and then run `pod install` from the Example directory to install the SDK as a dependency on the project, and then open the `metamask-ios-sdk.xcworkspace`

## Requirements
This SDK has an iOS minimum version requirement of 14.0. You need your app to have an iOS minimum deployment of no less than 14.0.
