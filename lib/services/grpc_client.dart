import 'package:grpc/grpc.dart';
import '../protos/compte_service.pbgrpc.dart';

class GrpcClient {
  static final GrpcClient _singleton = GrpcClient._internal();

  factory GrpcClient() {
    return _singleton;
  }

  GrpcClient._internal();

  late ClientChannel _channel;
  late CompteServiceClient _client;

  void init() {
    _channel = ClientChannel(
      '192.168.0.104', 
      port: 9090,   
      options: const ChannelOptions(
        credentials: ChannelCredentials.insecure(),
      ),
    );
    _client = CompteServiceClient(_channel);
  }

  CompteServiceClient get client => _client;

  Future<void> shutdown() async {
    await _channel.shutdown();
  }
}
