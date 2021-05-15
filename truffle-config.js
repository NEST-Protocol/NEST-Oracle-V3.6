/**
 * Use this file to configure your truffle project. It's seeded with some
 * common settings for different networks and features like migrations,
 * compilation and testing. Uncomment the ones you need or modify
 * them to suit your project as necessary.
 *
 * More information about configuration can be found at:
 *
 * truffleframework.com/docs/advanced/configuration
 *
 * To deploy via Infura you'll need a wallet provider (like @truffle/hdwallet-provider)
 * to sign your transactions before they're sent to a remote public node. Infura accounts
 * are available for free at: infura.io/register.
 *
 * You'll also need a mnemonic - the twelve word phrase the wallet uses to generate
 * public/private key pairs. If you're publishing your code to GitHub make sure you load this
 * phrase from a file you've .gitignored so it doesn't accidentally become public.
 *
 */

const HDWalletProvider = require('@truffle/hdwallet-provider');

// Load `.env` file as configuration.
const envResult = require("dotenv").config();
//console.log(envResult);
if (envResult.error) {
  throw envResult.error;
}
const config = envResult.parsed;
//console.log(config);
//console.log(config.RINKEBY_MNEMONIC, config.RINKEBY_NODEADDR);
//console.log(config.ROPSTEN_MNEMONIC, config.ROPSTEN_NODEADDR);
//console.log(config.MAINNET_MNEMONIC, config.MAINNET_NODEADDR);
//console.log(config.BSCTESTNET_MNEMONIC, config.BSCTESTNET_NODEADDR);
//console.log(config.BSCMAINNET_MNEMONIC, config.BSCMAINNET_NODEADDR);
//console.log(config.HECOTESTNET_MNEMONIC, config.HECOTESTNET_NODEADDR);
//console.log(config.HECOMAINNET_MNEMONIC, config.HECOMAINNET_NODEADDR);

module.exports = {
  /**
   * Networks define how you connect to your ethereum client and let you set the
   * defaults web3 uses to send transactions. If you don't specify one truffle
   * will spin up a development blockchain for you on port 9545 when you
   * run `develop` or `test`. You can ask a truffle command to use a specific
   * network from the command line, e.g
   *
   * $ truffle test --network <network-name>
   */

  networks: {
    // Useful for testing. The `development` name is special - truffle uses it by default
    // if it's defined here and no other network is specified at the command line.
    // You should run a client (like ganache-cli, geth or parity) in a separate terminal
    // tab if you use this network and you must also set the `host`, `port` and `network_id`
    // options below to some value.
    //
    development: {
     host: "127.0.0.1",     // Localhost (default: none)
     port: 7545,            // Standard Ethereum port (default: none)
     network_id: "*",       // Any network (default: none)
     timeoutBlocks: 200,  // # of blocks before a deployment times out  (minimum/default: 50)
    },

    // Another network with more advanced options...
    // advanced: {
      // port: 8777,             // Custom port
      // network_id: 1342,       // Custom network
      // gas: 8500000,           // Gas sent with each transaction (default: ~6700000)
      // gasPrice: 20000000000,  // 20 gwei (in wei) (default: 100 gwei)
      // from: <address>,        // Account to send txs from (default: accounts[0])
      // websockets: true        // Enable EventEmitter interface for web3 (default: false)
    // },

    // Useful for deploying to a public network.
    // NB: It's important to wrap the provider as a function.
    rinkeby: {
      provider: () => new HDWalletProvider({
        privateKeys: [config.RINKEBY_MNEMONIC],
        providerOrUrl: config.RINKEBY_NODEADDR,
        chainId: 4,
      }),
      //provider: () => new HDWalletProvider(mnemonic, `https://ropsten.infura.io/v3/YOUR-PROJECT-ID`),
      network_id: 4,       // Ropsten's id
      gas: 8000000,        // Ropsten has a lower block limit than mainnet
      gasPrice: 100000000000,
      confirmations: 1,    // # of confs to wait between deployments. (default: 0)
      timeoutBlocks: 200,  // # of blocks before a deployment times out  (minimum/default: 50)
      skipDryRun: false     // Skip dry run before migrations? (default: false for public nets )
    },

    // Useful for deploying to a public network.
    // NB: It's important to wrap the provider as a function.
    ropsten: {
      provider: () => new HDWalletProvider({
        privateKeys: [config.ROPSTEN_MNEMONIC],
        providerOrUrl: config.ROPSTEN_NODEADDR,
        chainId: 3,
      }),
      //provider: () => new HDWalletProvider(mnemonic, `https://ropsten.infura.io/v3/YOUR-PROJECT-ID`),
      network_id: 3,       // Ropsten's id
      gas: 8000000,        // Ropsten has a lower block limit than mainnet
      gasPrice: 100000000000,
      confirmations: 1,    // # of confs to wait between deployments. (default: 0)
      timeoutBlocks: 200,  // # of blocks before a deployment times out  (minimum/default: 50)
      skipDryRun: false     // Skip dry run before migrations? (default: false for public nets )
    },

    // Useful for deploying to a public network.
    // NB: It's important to wrap the provider as a function.
    mainnet: {
      provider: () => new HDWalletProvider({
        privateKeys: [config.MAINNET_MNEMONIC],
        providerOrUrl: config.MAINNET_NODEADDR,
        chainId: 1,
      }),
      //provider: () => new HDWalletProvider(mnemonic, `https://ropsten.infura.io/v3/YOUR-PROJECT-ID`),
      network_id: 1,       // Mainnet's id
      gas: 8000000,        // Mainnet has a lower block limit than mainnet
      gasPrice: 80000000000,
      confirmations: 2,    // # of confs to wait between deployments. (default: 0)
      timeoutBlocks: 200,  // # of blocks before a deployment times out  (minimum/default: 50)
      skipDryRun: true     // Skip dry run before migrations? (default: false for public nets )
    },

    // Settings for Binance Smart Chain(BSC)
    // See [Truffle - Binance Chain Docs](https://docs.binance.org/smart-chain/developer/deploy/truffle.html)
    // bsctestnet: BSC Testnet
    bsctestnet: {
      // NB: It's important to wrap the provider as a function.
      provider: () => new HDWalletProvider({
        privateKeys: [config.BSCTESTNET_MNEMONIC],
        providerOrUrl: config.BSCTESTNET_NODEADDR,
      }),
      //provider: () => new HDWalletProvider(mnemonic, 'https://data-seed-prebsc-1-s1.binance.org:8545'),
      network_id: 97,
      confirmations: 10,
      timeoutBlocks: 200,
      skipDryRun: true,
    },
    // bscmainnet: BSC Mainnet
    bscmainnet: {
      // NB: It's important to wrap the provider as a function.
      provider: () => new HDWalletProvider({
        privateKeys: [config.BSCMAINNET_MNEMONIC],
        providerOrUrl: config.BSCMAINNET_NODEADDR,
      }),
      //provider: () => new HDWalletProvider(mnemonic, 'https://bsc-dataseed1.binance.org'),
      network_id: 56,
      confirmations: 10,
      timeoutBlocks: 200,
      skipDryRun: true,
    },

    // Settings for Huobi ECO Chain(HECO)
    // See https://docs.hecochain.com/#/dev/contract?id=%e4%bd%bf%e7%94%a8truffle%e9%83%a8%e7%bd%b2%e5%90%88%e7%ba%a6
    // hecotestnet: HECO Testnet
    hecotestnet: {
      // NB: It's important to wrap the provider as a function.
      provider: () => new HDWalletProvider({
        privateKeys: [config.HECOTESTNET_MNEMONIC],
        providerOrUrl: config.HECOTESTNET_NODEADDR,
      }),
      //provider: () => new HDWalletProvider(mnemonic, 'https://http-testnet.hecochain.com'),
      network_id: 256
    },
    // hecomainnet: HECO Mainnet
    hecomainnet: {
      // NB: It's important to wrap the provider as a function.
      provider: () => new HDWalletProvider({
        privateKeys: [config.HECOMAINNET_MNEMONIC],
        providerOrUrl: config.HECOMAINNET_NODEADDR,
      }),
      //provider: () => new HDWalletProvider(mnemonic, 'https://http-mainnet.hecochain.com'),
      network_id: 128
    }

    // Useful for private networks
    // private: {
      // provider: () => new HDWalletProvider(mnemonic, `https://network.io`),
      // network_id: 2111,   // This network is yours, in the cloud.
      // production: true    // Treats this network as if it was a public net. (default: false)
    // }
  },

  // Set default mocha options here, use special reporters etc.
  mocha: {
    timeout: 2000000000
  },

  // Configure your compilers
  compilers: {
    solc: {
      version: "0.8.3",    // Fetch exact version from solc-bin (default: truffle's version)
      docker: false,        // Use "0.5.1" you've installed locally with docker (default: false)
      settings: {          // See the solidity docs for advice about optimization and evmVersion
       optimizer: {
         enabled: true,
         runs: 256
       }//,
       //evmVersion: "byzantium"
      }
    }
  }
}
