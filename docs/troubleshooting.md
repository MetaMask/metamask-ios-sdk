# Troubleshooting

## App opens but no connection happens
- Verify deeplink scheme is correct
- Confirm MetaMask Mobile version meets the minimum requirement
- Try a physical device if the simulator blocks deeplinks

## Session establishes but requests fail
- Check chainId / network mismatch
- Confirm request payload shape
- Ensure the dapp is using the expected RPC endpoint

## Debug tips
- Log the raw request/response
- Include timestamps for each step
- Reproduce with the smallest possible example
