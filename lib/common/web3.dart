import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';
import 'package:wallet/wallet.dart';

import 'constants.dart';

Future<int?> depositCheck(String account) async {
  final client = Web3Client(defaultRpc, Client());
  final client2 = Web3Client(defaultRpc2, Client());

  try {
    // check usdt
    final contract1 = DeployedContract(
      ContractAbi.fromJson(abi, 'USDT'),
      EthereumAddress.fromHex(usdtAddress),
    );
    final balanceOfFunction1 = contract1.function('balanceOf');
    final result1 = await client.call(
      contract: contract1,
      function: balanceOfFunction1,
      params: [EthereumAddress.fromHex(account)],
    );
    // decimal is 6
    final balance1 = ((result1[0] as BigInt).toInt() / 1000000).toInt();
    if (balance1 >= 10) {
      await client.dispose();
      await client2.dispose();
      return balance1;
    }

    // build usdc
    final contract2 = DeployedContract(
      ContractAbi.fromJson(abi, 'USDC'),
      EthereumAddress.fromHex(usdcAddress),
    );
    final balanceOfFunction2 = contract2.function('balanceOf');
    final result2 = await client.call(
      contract: contract2,
      function: balanceOfFunction2,
      params: [EthereumAddress.fromHex(account)],
    );
    // decimal is 6
    final balance2 = ((result2[0] as BigInt).toInt() / 1000000).toInt();
    if (balance2 >= 10) {
      await client.dispose();
      await client2.dispose();
      return balance2;
    }

    // build own token
    final contract3 = DeployedContract(
      ContractAbi.fromJson(abi, 'USD'),
      EthereumAddress.fromHex(usdsAddress),
    );
    final balanceOfFunction3 = contract3.function('balanceOf');
    final result3 = await client2.call(
      contract: contract3,
      function: balanceOfFunction3,
      params: [EthereumAddress.fromHex(account)],
    );
    // decimal is 6
    final balance3 = ((result3[0] as BigInt).toInt() / 1000000).toInt();

    await client.dispose();
    await client2.dispose();
    return balance3;
  } catch (e) {
    await client.dispose();
    await client2.dispose();
    return null;
  }
}
