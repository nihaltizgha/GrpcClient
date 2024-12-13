import 'package:flutter/material.dart';
import '../services/grpc_client.dart';
import '../protos/compte_service.pb.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Compte> comptes = [];
  TypeCompte? selectedType;

  @override
  void initState() {
    super.initState();
    fetchComptes();
  }

  Future<void> fetchComptes() async {
    final client = GrpcClient().client;
    try {
      final response = await client.allComptes(GetAllComptesRequest());
      setState(() {
        comptes = response.comptes;
      });
    } catch (e) {
      print('Error fetching comptes: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error fetching comptes.')),
      );
    }
  }

  Future<void> showTotalSoldeDialog(BuildContext context) async {
    final client = GrpcClient().client;
    try {
      final response = await client.totalSolde(GetTotalSoldeRequest());
      final stats = response.stats;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Total Solde Stats', style: TextStyle(color: Colors.blue)),
          content: Text(
            'Count: ${stats.count}\nSum: ${stats.sum}\nAverage: ${stats.average}',
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close', style: TextStyle(color: Colors.blue)),
            ),
          ],
        ),
      );
    } catch (e) {
      print('Error fetching total solde: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error fetching total solde.')),
      );
    }
  }

  Future<void> showSaveCompteForm(BuildContext context) async {
    final TextEditingController soldeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Add Compte', style: TextStyle(color: Colors.blue)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: soldeController,
                decoration: const InputDecoration(
                  labelText: 'Solde',
                  border: OutlineInputBorder(),
                  labelStyle: TextStyle(color: Colors.blue),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              const Text('Select Type:', style: TextStyle(color: Colors.blue)),
              DropdownButton<TypeCompte>(
                value: selectedType,
                onChanged: (TypeCompte? newValue) {
                  setState(() {
                    selectedType = newValue;
                  });
                },
                items: TypeCompte.values.map<DropdownMenuItem<TypeCompte>>((TypeCompte value) {
                  return DropdownMenuItem<TypeCompte>(
                    value: value,
                    child: Text(value == TypeCompte.COURANT ? 'COURANT' : 'EPARGNE'),
                  );
                }).toList(),
                hint: const Text('Select Type'),
                isExpanded: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              onPressed: () async {
                final solde = double.tryParse(soldeController.text);

                if (solde != null && selectedType != null) {
                  final compteRequest = CompteRequest(
                    solde: solde,
                    dateCreation: DateTime.now().toIso8601String(),
                    type: selectedType!,
                  );

                  final client = GrpcClient().client;
                  await client.saveCompte(SaveCompteRequest(compte: compteRequest));
                  fetchComptes();
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invalid inputs! Check solde and type.')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> searchCompteById(BuildContext context) async {
    final TextEditingController idController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Search Compte', style: TextStyle(color: Colors.blue)),
        content: TextField(
          controller: idController,
          decoration: const InputDecoration(
            labelText: 'Enter Compte ID',
            border: OutlineInputBorder(),
            labelStyle: TextStyle(color: Colors.blue),
          ),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () async {
              final id = int.tryParse(idController.text);
              if (id != null) {
                try {
                  final client = GrpcClient().client;
                  final response = await client.compteById(GetCompteByIdRequest(id: id));
                  final compte = response.compte;
                  Navigator.of(context).pop();
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      title: const Text('Compte Details', style: TextStyle(color: Colors.blue)),
                      content: Text(
                        'ID: ${compte.id}\nSolde: ${compte.solde}\nType: ${compte.type}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Close', style: TextStyle(color: Colors.blue)),
                        ),
                      ],
                    ),
                  );
                } catch (e) {
                  print('Error fetching compte: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Compte not found.')),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invalid ID.')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  Future<void> deleteCompteById(int id) async {
    final client = GrpcClient().client;
    try {
      await client.deleteCompte(DeleteCompteRequest(id: id));
      setState(() {
        comptes.removeWhere((compte) => compte.id == id);
      });
    } catch (e) {
      print('Error deleting compte: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error deleting compte.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Liste des Comptes'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => searchCompteById(context),
          ),
        ],
      ),
      body: comptes.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: comptes.length,
              itemBuilder: (context, index) {
                final compte = comptes[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: 8,
                  color: Colors.blue.shade50,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: ListTile(
                    title: Text(
                      'Compte ID: ${compte.id}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('Solde: ${compte.solde}'),
                    trailing: ElevatedButton(
                      onPressed: () => deleteCompteById(compte.id),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text('Supprimer'),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showSaveCompteForm(context),
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
    );
  }
}
