// SPDX-License-Identifier: CAL
pragma solidity =0.8.19;

import {Script} from "forge-std/Script.sol";
import {OrderBook} from "src/concrete/ob/OrderBook.sol";
import {OrderBookSubParser} from "src/concrete/parser/OrderBookSubParser.sol";
import {GenericPoolOrderBookV3ArbOrderTaker} from "src/concrete/arb/GenericPoolOrderBookV3ArbOrderTaker.sol";
import {RouteProcessorOrderBookV3ArbOrderTaker} from "src/concrete/arb/RouteProcessorOrderBookV3ArbOrderTaker.sol";
import {GenericPoolOrderBookV3FlashBorrower} from "src/concrete/arb/GenericPoolOrderBookV3FlashBorrower.sol";
import {EvaluableConfigV3, IExpressionDeployerV3} from "rain.orderbook.interface/interface/IOrderBookV3.sol";
import {OrderBookV3ArbConfigV1} from "src/abstract/OrderBookV3ArbCommon.sol";
import {IMetaBoardV1} from "rain.metadata/interface/IMetaBoardV1.sol";
import {LibDescribedByMeta} from "rain.metadata/lib/LibDescribedByMeta.sol";

/// @dev Exact bytecode taken from sushiswap deployments list in github.
/// https://github.com/sushiswap/sushiswap/blob/master/protocols/route-processor/deployments/ethereum/RouteProcessor3_2.json#L330
///
/// Cross referenced against deployment on etherscan.
/// https://etherscan.io/address/0x5550D13389bB70F45fCeF58f19f6b6e87F6e747d#code
///
/// Includes constructor args found on etherscan which translate to `address(0)`
/// for the bento (i.e. no bento) and no owner addresses.
bytes constant ROUTE_PROCESSOR_3_2_CREATION_CODE =
    hex"60a06040526002805461ffff60a01b191661010160a01b1790553480156200002657600080fd5b50604051620038a1380380620038a183398101604081905262000049916200016e565b6200005433620000eb565b6001600160a01b038216608052600280546001600160a01b031916600117905560005b8151811015620000e25760018060008484815181106200009b576200009b62000257565b6020908102919091018101516001600160a01b03168252810191909152604001600020805460ff191691151591909117905580620000d9816200026d565b91505062000077565b50505062000297565b600080546001600160a01b038381166001600160a01b0319831681178455604051919092169283917f8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e09190a35050565b80516001600160a01b03811681146200015357600080fd5b919050565b634e487b7160e01b600052604160045260246000fd5b600080604083850312156200018257600080fd5b6200018d836200013b565b602084810151919350906001600160401b0380821115620001ad57600080fd5b818601915086601f830112620001c257600080fd5b815181811115620001d757620001d762000158565b8060051b604051601f19603f83011681018181108582111715620001ff57620001ff62000158565b6040529182528482019250838101850191898311156200021e57600080fd5b938501935b82851015620002475762000237856200013b565b8452938501939285019262000223565b8096505050505050509250929050565b634e487b7160e01b600052603260045260246000fd5b60006000198214156200029057634e487b7160e01b600052601160045260246000fd5b5060010190565b6080516135a16200030060003960008181610110015281816115090152818161245e015281816124a50152818161250f015281816125d401528181612681015281816127650152818161285601528181612902015281816129d10152612acd01526135a16000f3fe6080604052600436106100b55760003560e01c80638da5cb5b116100695780639a1f34061161004e5780639a1f3406146101bf578063f2fde38b146101df578063fa461e33146101ff57600080fd5b80638da5cb5b1461018157806393b3774c146101ac57600080fd5b80636b2ace871161009a5780636b2ace87146100fe578063715018a6146101575780638456cb591461016c57600080fd5b8063046f7da2146100c15780632646478b146100d857600080fd5b366100bc57005b600080fd5b3480156100cd57600080fd5b506100d661021f565b005b6100eb6100e6366004612f14565b61032d565b6040519081526020015b60405180910390f35b34801561010a57600080fd5b506101327f000000000000000000000000000000000000000000000000000000000000000081565b60405173ffffffffffffffffffffffffffffffffffffffff90911681526020016100f5565b34801561016357600080fd5b506100d66104d7565b34801561017857600080fd5b506100d66104eb565b34801561018d57600080fd5b5060005473ffffffffffffffffffffffffffffffffffffffff16610132565b6100eb6101ba366004612f9b565b6105f4565b3480156101cb57600080fd5b506100d66101da36600461304e565b610860565b3480156101eb57600080fd5b506100d66101fa366004613087565b6108be565b34801561020b57600080fd5b506100d661021a3660046130ab565b610975565b60005473ffffffffffffffffffffffffffffffffffffffff1633148061025a57503360009081526001602081905260409091205460ff161515145b6102eb576040517f08c379a000000000000000000000000000000000000000000000000000000000815260206004820152603160248201527f52503a2063616c6c6572206973206e6f7420746865206f776e6572206f72206160448201527f2070726976696c6564676564207573657200000000000000000000000000000060648201526084015b60405180910390fd5b600280547fffffffffffffffffffff00ffffffffffffffffffffffffffffffffffffffffff167501000000000000000000000000000000000000000000179055565b60025460009074010000000000000000000000000000000000000000900460ff166001146103b7576040517f08c379a000000000000000000000000000000000000000000000000000000000815260206004820152601860248201527f526f75746550726f636573736f72206973206c6f636b6564000000000000000060448201526064016102e2565b6002547501000000000000000000000000000000000000000000900460ff1660011461043f576040517f08c379a000000000000000000000000000000000000000000000000000000000815260206004820152601860248201527f526f75746550726f636573736f7220697320706175736564000000000000000060448201526064016102e2565b600280547fffffffffffffffffffffff00ffffffffffffffffffffffffffffffffffffffff167402000000000000000000000000000000000000000017905561048c878787878787610b23565b9050600280547fffffffffffffffffffffff00ffffffffffffffffffffffffffffffffffffffff16740100000000000000000000000000000000000000001790559695505050505050565b6104df611180565b6104e96000611201565b565b60005473ffffffffffffffffffffffffffffffffffffffff1633148061052657503360009081526001602081905260409091205460ff161515145b6105b2576040517f08c379a000000000000000000000000000000000000000000000000000000000815260206004820152603160248201527f52503a2063616c6c6572206973206e6f7420746865206f776e6572206f72206160448201527f2070726976696c6564676564207573657200000000000000000000000000000060648201526084016102e2565b600280547fffffffffffffffffffff00ffffffffffffffffffffffffffffffffffffffffff167502000000000000000000000000000000000000000000179055565b60025460009074010000000000000000000000000000000000000000900460ff1660011461067e576040517f08c379a000000000000000000000000000000000000000000000000000000000815260206004820152601860248201527f526f75746550726f636573736f72206973206c6f636b6564000000000000000060448201526064016102e2565b6002547501000000000000000000000000000000000000000000900460ff16600114610706576040517f08c379a000000000000000000000000000000000000000000000000000000000815260206004820152601860248201527f526f75746550726f636573736f7220697320706175736564000000000000000060448201526064016102e2565b600280547fffffffffffffffffffffff00ffffffffffffffffffffffffffffffffffffffff1674020000000000000000000000000000000000000000179055604051600090819073ffffffffffffffffffffffffffffffffffffffff8c16908b908381818185875af1925050503d806000811461079f576040519150601f19603f3d011682016040523d82523d6000602084013e6107a4565b606091505b509150915081816040516020016107bb9190613157565b60405160208183030381529060405290610802576040517f08c379a00000000000000000000000000000000000000000000000000000000081526004016102e291906131bd565b50610811898989898989610b23565b92505050600280547fffffffffffffffffffffff00ffffffffffffffffffffffffffffffffffffffff167401000000000000000000000000000000000000000017905598975050505050505050565b610868611180565b73ffffffffffffffffffffffffffffffffffffffff91909116600090815260016020526040902080547fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0016911515919091179055565b6108c6611180565b73ffffffffffffffffffffffffffffffffffffffff8116610969576040517f08c379a000000000000000000000000000000000000000000000000000000000815260206004820152602660248201527f4f776e61626c653a206e6577206f776e657220697320746865207a65726f206160448201527f646472657373000000000000000000000000000000000000000000000000000060648201526084016102e2565b61097281611201565b50565b60025473ffffffffffffffffffffffffffffffffffffffff163314610a1c576040517f08c379a000000000000000000000000000000000000000000000000000000000815260206004820152603e60248201527f526f75746550726f636573736f722e756e697377617056335377617043616c6c60448201527f6261636b3a2063616c6c2066726f6d20756e6b6e6f776e20736f75726365000060648201526084016102e2565b600280547fffffffffffffffffffffffff00000000000000000000000000000000000000001660011790556000610a5582840184613087565b90506000808613610a665784610a68565b855b905060008113610afa576040517f08c379a000000000000000000000000000000000000000000000000000000000815260206004820152603960248201527f526f75746550726f636573736f722e756e697377617056335377617043616c6c60448201527f6261636b3a206e6f7420706f73697469766520616d6f756e740000000000000060648201526084016102e2565b610b1b73ffffffffffffffffffffffffffffffffffffffff83163383611276565b505050505050565b60008073ffffffffffffffffffffffffffffffffffffffff881673eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee14610bea576040517f70a0823100000000000000000000000000000000000000000000000000000000815233600482015273ffffffffffffffffffffffffffffffffffffffff8916906370a0823190602401602060405180830381865afa158015610bc1573d6000803e3d6000fd5b505050506040513d601f19601f82011682018060405250810190610be591906131d0565b610bec565b475b9050600073ffffffffffffffffffffffffffffffffffffffff871673eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee14610cb6576040517f70a0823100000000000000000000000000000000000000000000000000000000815273ffffffffffffffffffffffffffffffffffffffff86811660048301528816906370a0823190602401602060405180830381865afa158015610c8d573d6000803e3d6000fd5b505050506040513d601f19601f82011682018060405250810190610cb191906131d0565b610ccf565b8473ffffffffffffffffffffffffffffffffffffffff16315b604080518082019091528581528551860160208201529091505b805160208201511115610e1c576000610d088280516001018051915290565b90508060ff1660011415610d2457610d1f8261134f565b610e16565b8060ff1660021415610d3a57610d1f828b61142c565b8060ff1660031415610d4f57610d1f8261144c565b8060ff1660041415610d6457610d1f82611471565b8060ff1660051415610d7957610d1f82611492565b8060ff1660061415610d8f57610d1f8b836115ed565b6040517f08c379a0000000000000000000000000000000000000000000000000000000008152602060048201526024808201527f526f75746550726f636573736f723a20556e6b6e6f776e20636f6d6d616e642060448201527f636f64650000000000000000000000000000000000000000000000000000000060648201526084016102e2565b50610ce9565b600073ffffffffffffffffffffffffffffffffffffffff8b1673eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee14610ee2576040517f70a0823100000000000000000000000000000000000000000000000000000000815233600482015273ffffffffffffffffffffffffffffffffffffffff8c16906370a0823190602401602060405180830381865afa158015610eb9573d6000803e3d6000fd5b505050506040513d601f19601f82011682018060405250810190610edd91906131d0565b610ee4565b475b905083610ef18b83613218565b1015610f7f576040517f08c379a000000000000000000000000000000000000000000000000000000000815260206004820152602f60248201527f526f75746550726f636573736f723a204d696e696d616c20696d70757420626160448201527f6c616e63652076696f6c6174696f6e000000000000000000000000000000000060648201526084016102e2565b600073ffffffffffffffffffffffffffffffffffffffff8a1673eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee14611047576040517f70a0823100000000000000000000000000000000000000000000000000000000815273ffffffffffffffffffffffffffffffffffffffff89811660048301528b16906370a0823190602401602060405180830381865afa15801561101e573d6000803e3d6000fd5b505050506040513d601f19601f8201168201806040525081019061104291906131d0565b611060565b8773ffffffffffffffffffffffffffffffffffffffff16315b905061106c8985613218565b8110156110fb576040517f08c379a000000000000000000000000000000000000000000000000000000000815260206004820152602f60248201527f526f75746550726f636573736f723a204d696e696d616c206f7570757420626160448201527f6c616e63652076696f6c6174696f6e000000000000000000000000000000000060648201526084016102e2565b6111058482613230565b6040805173ffffffffffffffffffffffffffffffffffffffff8b81168252602082018f90529181018c905260608101839052919750808c1691908e169033907f2db5ddd0b42bdbca0d69ea16f234a870a485854ae0d91f16643d6f317d8b89949060800160405180910390a450505050509695505050505050565b60005473ffffffffffffffffffffffffffffffffffffffff1633146104e9576040517f08c379a000000000000000000000000000000000000000000000000000000000815260206004820181905260248201527f4f776e61626c653a2063616c6c6572206973206e6f7420746865206f776e657260448201526064016102e2565b6000805473ffffffffffffffffffffffffffffffffffffffff8381167fffffffffffffffffffffffff0000000000000000000000000000000000000000831681178455604051919092169283917f8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e09190a35050565b60405173ffffffffffffffffffffffffffffffffffffffff831660248201526044810182905261134a9084907fa9059cbb00000000000000000000000000000000000000000000000000000000906064015b604080517fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe08184030181529190526020810180517bffffffffffffffffffffffffffffffffffffffffffffffffffffffff167fffffffff0000000000000000000000000000000000000000000000000000000090931692909217909152611680565b505050565b60006113618280516014018051915290565b6040517f70a0823100000000000000000000000000000000000000000000000000000000815230600482015290915060009073ffffffffffffffffffffffffffffffffffffffff8316906370a0823190602401602060405180830381865afa1580156113d1573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052508101906113f591906131d0565b90508015611420577fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff015b61134a8330848461178c565b600061143e8380516014018051915290565b905061134a8333838561178c565b4761146d823073eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee8461178c565b5050565b60006114838280516014018051915290565b905061146d82308360006117e7565b60006114a48280516014018051915290565b905060006114b88380516001018051915290565b6040517ff7888aec00000000000000000000000000000000000000000000000000000000815273ffffffffffffffffffffffffffffffffffffffff84811660048301523060248301529192506000917f0000000000000000000000000000000000000000000000000000000000000000169063f7888aec90604401602060405180830381865afa158015611550573d6000803e3d6000fd5b505050506040513d601f19601f8201168201806040525081019061157491906131d0565b9050801561159f577fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff015b60005b8260ff168110156115e65760006115bf8680516002018051915290565b61ffff80821685020493849003939091506115dc873088846117e7565b50506001016115a2565b5050505050565b60006115ff8280516020018051915290565b905060006116138380516020018051915290565b905060006116278480516001018051915290565b9050600061163b8580516020018051915290565b9050600061164f8680516020018051915290565b905061167773ffffffffffffffffffffffffffffffffffffffff8816333088888888886118fc565b50505050505050565b60006116e2826040518060400160405280602081526020017f5361666545524332303a206c6f772d6c6576656c2063616c6c206661696c65648152508573ffffffffffffffffffffffffffffffffffffffff16611b7c9092919063ffffffff16565b80519091501561134a57808060200190518101906117009190613247565b61134a576040517f08c379a000000000000000000000000000000000000000000000000000000000815260206004820152602a60248201527f5361666545524332303a204552433230206f7065726174696f6e20646964206e60448201527f6f7420737563636565640000000000000000000000000000000000000000000060648201526084016102e2565b600061179e8580516001018051915290565b905060005b8160ff16811015610b1b5760006117c08780516002018051915290565b61ffff80821686020494859003949091506117dd888888846117e7565b50506001016117a3565b60006117f98580516001018051915290565b905060ff81166118145761180f85858585611b93565b6115e6565b8060ff166001141561182c5761180f85858585611f0a565b8060ff16600214156118445761180f858585856121ee565b8060ff166003141561185c5761180f858585856123ed565b8060ff16600414156118745761180f85858585612a47565b6040517f08c379a000000000000000000000000000000000000000000000000000000000815260206004820152602160248201527f526f75746550726f636573736f723a20556e6b6e6f776e20706f6f6c2074797060448201527f650000000000000000000000000000000000000000000000000000000000000060648201526084016102e2565b6040517f7ecebe0000000000000000000000000000000000000000000000000000000000815273ffffffffffffffffffffffffffffffffffffffff8881166004830152600091908a1690637ecebe0090602401602060405180830381865afa15801561196c573d6000803e3d6000fd5b505050506040513d601f19601f8201168201806040525081019061199091906131d0565b6040517fd505accf00000000000000000000000000000000000000000000000000000000815273ffffffffffffffffffffffffffffffffffffffff8a811660048301528981166024830152604482018990526064820188905260ff8716608483015260a4820186905260c48201859052919250908a169063d505accf9060e401600060405180830381600087803b158015611a2a57600080fd5b505af1158015611a3e573d6000803e3d6000fd5b50506040517f7ecebe0000000000000000000000000000000000000000000000000000000000815273ffffffffffffffffffffffffffffffffffffffff8b81166004830152600093508c169150637ecebe0090602401602060405180830381865afa158015611ab1573d6000803e3d6000fd5b505050506040513d601f19601f82011682018060405250810190611ad591906131d0565b9050611ae2826001613218565b8114611b70576040517f08c379a000000000000000000000000000000000000000000000000000000000815260206004820152602160248201527f5361666545524332303a207065726d697420646964206e6f742073756363656560448201527f640000000000000000000000000000000000000000000000000000000000000060648201526084016102e2565b50505050505050505050565b6060611b8b8484600085612bbf565b949350505050565b6000611ba58580516014018051915290565b90506000611bb98680516001018051915290565b90506000611bcd8780516014018051915290565b90508315611c3b5773ffffffffffffffffffffffffffffffffffffffff8616301415611c1957611c1473ffffffffffffffffffffffffffffffffffffffff86168486611276565b611c3b565b611c3b73ffffffffffffffffffffffffffffffffffffffff8616878587612cd8565b6000808473ffffffffffffffffffffffffffffffffffffffff16630902f1ac6040518163ffffffff1660e01b8152600401606060405180830381865afa158015611c89573d6000803e3d6000fd5b505050506040513d601f19601f82011682018060405250810190611cad9190613287565b506dffffffffffffffffffffffffffff1691506dffffffffffffffffffffffffffff169150600082118015611ce25750600081115b611d48576040517f08c379a000000000000000000000000000000000000000000000000000000000815260206004820152601360248201527f57726f6e6720706f6f6c2072657365727665730000000000000000000000000060448201526064016102e2565b6000808560ff16600114611d5d578284611d60565b83835b6040517f70a0823100000000000000000000000000000000000000000000000000000000815273ffffffffffffffffffffffffffffffffffffffff8a8116600483015292945090925083918b16906370a0823190602401602060405180830381865afa158015611dd4573d6000803e3d6000fd5b505050506040513d601f19601f82011682018060405250810190611df891906131d0565b611e029190613230565b97506000611e12896103e56132d7565b9050600081611e23856103e86132d7565b611e2d9190613218565b611e3784846132d7565b611e419190613314565b90506000808960ff16600114611e5957826000611e5d565b6000835b604080516000815260208101918290527f022c0d9f00000000000000000000000000000000000000000000000000000000909152919350915073ffffffffffffffffffffffffffffffffffffffff8c169063022c0d9f90611ec790859085908e906024810161334f565b600060405180830381600087803b158015611ee157600080fd5b505af1158015611ef5573d6000803e3d6000fd5b50505050505050505050505050505050505050565b6000611f1c8580516014018051915290565b9050600080611f318780516001018051915290565b60ff161190506000611f498780516014018051915290565b905073ffffffffffffffffffffffffffffffffffffffff8616301461202f5773ffffffffffffffffffffffffffffffffffffffff8616331461200d576040517f08c379a000000000000000000000000000000000000000000000000000000000815260206004820152602260248201527f73776170556e6956333a20756e65787065637465642066726f6d20616464726560448201527f737300000000000000000000000000000000000000000000000000000000000060648201526084016102e2565b61202f73ffffffffffffffffffffffffffffffffffffffff8616333087612cd8565b600280547fffffffffffffffffffffffff00000000000000000000000000000000000000001673ffffffffffffffffffffffffffffffffffffffff851690811790915563128acb08828487816120a35761209e600173fffd8963efd1fc6a506488495d951d5263988d26613394565b6120b3565b6120b36401000276a360016133c9565b6040805173ffffffffffffffffffffffffffffffffffffffff8d166020820152016040516020818303038152906040526040518663ffffffff1660e01b8152600401612103959493929190613401565b60408051808303816000875af1158015612121573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052508101906121459190613448565b505060025473ffffffffffffffffffffffffffffffffffffffff16600114611677576040517f08c379a0000000000000000000000000000000000000000000000000000000008152602060048201526024808201527f526f75746550726f636573736f722e73776170556e6956333a20756e6578706560448201527f637465640000000000000000000000000000000000000000000000000000000060648201526084016102e2565b60006122008580516001018051915290565b905060006122148680516014018051915290565b9050600180831614156122e35760006122338780516014018051915290565b90506002831661229f578073ffffffffffffffffffffffffffffffffffffffff1663d0e30db0856040518263ffffffff1660e01b81526004016000604051808303818588803b15801561228557600080fd5b505af1158015612299573d6000803e3d6000fd5b50505050505b73ffffffffffffffffffffffffffffffffffffffff821630146122dd576122dd73ffffffffffffffffffffffffffffffffffffffff82168386611276565b50610b1b565b600282166123ab5773ffffffffffffffffffffffffffffffffffffffff8516301461232a5761232a73ffffffffffffffffffffffffffffffffffffffff8516863086612cd8565b6040517f2e1a7d4d0000000000000000000000000000000000000000000000000000000081526004810184905273ffffffffffffffffffffffffffffffffffffffff851690632e1a7d4d90602401600060405180830381600087803b15801561239257600080fd5b505af11580156123a6573d6000803e3d6000fd5b505050505b60405173ffffffffffffffffffffffffffffffffffffffff8216904780156108fc02916000818181858888f19350505050158015611677573d6000803e3d6000fd5b60006123ff8580516001018051915290565b905060006124138680516014018051915290565b905060ff8216156127f65782156124ca5773ffffffffffffffffffffffffffffffffffffffff85163014156124885761248373ffffffffffffffffffffffffffffffffffffffff85167f000000000000000000000000000000000000000000000000000000000000000085611276565b612720565b61248373ffffffffffffffffffffffffffffffffffffffff8516867f000000000000000000000000000000000000000000000000000000000000000086612cd8565b6040517f4ffe34db00000000000000000000000000000000000000000000000000000000815273ffffffffffffffffffffffffffffffffffffffff85811660048301527f00000000000000000000000000000000000000000000000000000000000000001690634ffe34db906024016040805180830381865afa158015612555573d6000803e3d6000fd5b505050506040513d601f19601f82011682018060405250810190612579919061348c565b516040517fdf23b45b00000000000000000000000000000000000000000000000000000000815273ffffffffffffffffffffffffffffffffffffffff86811660048301526fffffffffffffffffffffffffffffffff909216917f0000000000000000000000000000000000000000000000000000000000000000169063df23b45b90602401606060405180830381865afa15801561261b573d6000803e3d6000fd5b505050506040513d601f19601f8201168201806040525081019061263f91906134ff565b60409081015190517f70a0823100000000000000000000000000000000000000000000000000000000815273ffffffffffffffffffffffffffffffffffffffff7f0000000000000000000000000000000000000000000000000000000000000000811660048301526fffffffffffffffffffffffffffffffff909216918716906370a0823190602401602060405180830381865afa1580156126e5573d6000803e3d6000fd5b505050506040513d601f19601f8201168201806040525081019061270991906131d0565b6127139190613218565b61271d9190613230565b92505b6040517f02b9446c00000000000000000000000000000000000000000000000000000000815273ffffffffffffffffffffffffffffffffffffffff85811660048301527f000000000000000000000000000000000000000000000000000000000000000081166024830181905290831660448301526064820185905260006084830152906302b9446c9060a40160408051808303816000875af11580156127cb573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052508101906127ef9190613448565b5050610b1b565b82156128b7576040517ff18d03cc00000000000000000000000000000000000000000000000000000000815273ffffffffffffffffffffffffffffffffffffffff85811660048301528681166024830152306044830152606482018590527f0000000000000000000000000000000000000000000000000000000000000000169063f18d03cc90608401600060405180830381600087803b15801561289a57600080fd5b505af11580156128ae573d6000803e3d6000fd5b50505050612970565b6040517ff7888aec00000000000000000000000000000000000000000000000000000000815273ffffffffffffffffffffffffffffffffffffffff85811660048301523060248301527f0000000000000000000000000000000000000000000000000000000000000000169063f7888aec90604401602060405180830381865afa158015612949573d6000803e3d6000fd5b505050506040513d601f19601f8201168201806040525081019061296d91906131d0565b92505b6040517f97da6d3000000000000000000000000000000000000000000000000000000000815273ffffffffffffffffffffffffffffffffffffffff8581166004830152306024830152828116604483015260006064830152608482018590527f000000000000000000000000000000000000000000000000000000000000000016906397da6d309060a40160408051808303816000875af1158015612a19573d6000803e3d6000fd5b505050506040513d601f19601f82011682018060405250810190612a3d9190613448565b5050505050505050565b6000612a598580516014018051915290565b8551602080820180519092010187529091508215612b2a576040517ff18d03cc00000000000000000000000000000000000000000000000000000000815273ffffffffffffffffffffffffffffffffffffffff858116600483015286811660248301528381166044830152606482018590527f0000000000000000000000000000000000000000000000000000000000000000169063f18d03cc90608401600060405180830381600087803b158015612b1157600080fd5b505af1158015612b25573d6000803e3d6000fd5b505050505b6040517f627dd56a00000000000000000000000000000000000000000000000000000000815273ffffffffffffffffffffffffffffffffffffffff83169063627dd56a90612b7c9084906004016131bd565b6020604051808303816000875af1158015612b9b573d6000803e3d6000fd5b505050506040513d601f19601f8201168201806040525081019061167791906131d0565b606082471015612c51576040517f08c379a000000000000000000000000000000000000000000000000000000000815260206004820152602660248201527f416464726573733a20696e73756666696369656e742062616c616e636520666f60448201527f722063616c6c000000000000000000000000000000000000000000000000000060648201526084016102e2565b6000808673ffffffffffffffffffffffffffffffffffffffff168587604051612c7a9190613157565b60006040518083038185875af1925050503d8060008114612cb7576040519150601f19603f3d011682016040523d82523d6000602084013e612cbc565b606091505b5091509150612ccd87838387612d3c565b979650505050505050565b60405173ffffffffffffffffffffffffffffffffffffffff80851660248301528316604482015260648101829052612d369085907f23b872dd00000000000000000000000000000000000000000000000000000000906084016112c8565b50505050565b60608315612dcf578251612dc85773ffffffffffffffffffffffffffffffffffffffff85163b612dc8576040517f08c379a000000000000000000000000000000000000000000000000000000000815260206004820152601d60248201527f416464726573733a2063616c6c20746f206e6f6e2d636f6e747261637400000060448201526064016102e2565b5081611b8b565b611b8b8383815115612de45781518083602001fd5b806040517f08c379a00000000000000000000000000000000000000000000000000000000081526004016102e291906131bd565b73ffffffffffffffffffffffffffffffffffffffff8116811461097257600080fd5b7f4e487b7100000000000000000000000000000000000000000000000000000000600052604160045260246000fd5b600082601f830112612e7a57600080fd5b813567ffffffffffffffff80821115612e9557612e95612e3a565b604051601f83017fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe0908116603f01168101908282118183101715612edb57612edb612e3a565b81604052838152866020858801011115612ef457600080fd5b836020870160208301376000602085830101528094505050505092915050565b60008060008060008060c08789031215612f2d57600080fd5b8635612f3881612e18565b9550602087013594506040870135612f4f81612e18565b9350606087013592506080870135612f6681612e18565b915060a087013567ffffffffffffffff811115612f8257600080fd5b612f8e89828a01612e69565b9150509295509295509295565b600080600080600080600080610100898b031215612fb857600080fd5b8835612fc381612e18565b9750602089013596506040890135612fda81612e18565b9550606089013594506080890135612ff181612e18565b935060a0890135925060c089013561300881612e18565b915060e089013567ffffffffffffffff81111561302457600080fd5b6130308b828c01612e69565b9150509295985092959890939650565b801515811461097257600080fd5b6000806040838503121561306157600080fd5b823561306c81612e18565b9150602083013561307c81613040565b809150509250929050565b60006020828403121561309957600080fd5b81356130a481612e18565b9392505050565b600080600080606085870312156130c157600080fd5b8435935060208501359250604085013567ffffffffffffffff808211156130e757600080fd5b818701915087601f8301126130fb57600080fd5b81358181111561310a57600080fd5b88602082850101111561311c57600080fd5b95989497505060200194505050565b60005b8381101561314657818101518382015260200161312e565b83811115612d365750506000910152565b6000825161316981846020870161312b565b9190910192915050565b6000815180845261318b81602086016020860161312b565b601f017fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe0169290920160200192915050565b6020815260006130a46020830184613173565b6000602082840312156131e257600080fd5b5051919050565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052601160045260246000fd5b6000821982111561322b5761322b6131e9565b500190565b600082821015613242576132426131e9565b500390565b60006020828403121561325957600080fd5b81516130a481613040565b80516dffffffffffffffffffffffffffff8116811461328257600080fd5b919050565b60008060006060848603121561329c57600080fd5b6132a584613264565b92506132b360208501613264565b9150604084015163ffffffff811681146132cc57600080fd5b809150509250925092565b6000817fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff048311821515161561330f5761330f6131e9565b500290565b60008261334a577f4e487b7100000000000000000000000000000000000000000000000000000000600052601260045260246000fd5b500490565b84815283602082015273ffffffffffffffffffffffffffffffffffffffff8316604082015260806060820152600061338a6080830184613173565b9695505050505050565b600073ffffffffffffffffffffffffffffffffffffffff838116908316818110156133c1576133c16131e9565b039392505050565b600073ffffffffffffffffffffffffffffffffffffffff8083168185168083038211156133f8576133f86131e9565b01949350505050565b600073ffffffffffffffffffffffffffffffffffffffff8088168352861515602084015285604084015280851660608401525060a06080830152612ccd60a0830184613173565b6000806040838503121561345b57600080fd5b505080516020909101519092909150565b80516fffffffffffffffffffffffffffffffff8116811461328257600080fd5b60006040828403121561349e57600080fd5b6040516040810181811067ffffffffffffffff821117156134c1576134c1612e3a565b6040526134cd8361346c565b81526134db6020840161346c565b60208201529392505050565b805167ffffffffffffffff8116811461328257600080fd5b60006060828403121561351157600080fd5b6040516060810181811067ffffffffffffffff8211171561353457613534612e3a565b604052613540836134e7565b815261354e602084016134e7565b602082015261355f6040840161346c565b6040820152939250505056fea26469706673582212205ac4c1035d254cf4feedf3887f8aae589900bdc8f79fee83f0f579f8de1a06e864736f6c634300080a0033000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000000";

/// @title Deploy
/// @notice A script that deploys all contracts. This is intended to be run on
/// every commit by CI to a testnet such as mumbai.
contract Deploy is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYMENT_KEY");
        bytes memory subParserDescribedByMeta = vm.readFileBinary("meta/OrderBookSubParserDescribedByMetaV1.rain.meta");
        IMetaBoardV1 metaboard = IMetaBoardV1(vm.envAddress("DEPLOY_METABOARD_ADDRESS"));

        vm.startBroadcast(deployerPrivateKey);

        // OB.
        OrderBook orderbook = new OrderBook();

        // Subparsers.
        OrderBookSubParser subParser = new OrderBookSubParser();
        LibDescribedByMeta.emitForDescribedAddress(metaboard, subParser, subParserDescribedByMeta);

        bytes memory routeProcessor3_2Code = ROUTE_PROCESSOR_3_2_CREATION_CODE;
        address routeProcessor3_2;
        assembly ("memory-safe") {
            routeProcessor3_2 := create(0, add(routeProcessor3_2Code, 0x20), mload(routeProcessor3_2Code))
        }

        // Order takers.
        new GenericPoolOrderBookV4ArbOrderTaker(
            OrderBookV4ArbConfigV1(
                address(orderbook), EvaluableV3(IInterpreterV3(address(0)), IInterpreterStoreV2(address(0)), ""), ""
            )
        );
        new RouteProcessorOrderBookV4ArbOrderTaker(
            OrderBookV4ArbConfigV1(
                address(orderbook),
                EvaluableV3(IInterpreterV3(address(0)), IInterpreterStoreV2(address(0)), ""),
                abi.encode(routeProcessor3_2)
            )
        );

        // Flash borrowers.
        new GenericPoolOrderBookV4FlashBorrower(
            OrderBookV4ArbConfigV1(
                address(orderbook), EvaluableV3(IInterpreterV3(address(0)), IInterpreterStoreV2(address(0)), ""), ""
            )
        );

        vm.stopBroadcast();
    }
}
