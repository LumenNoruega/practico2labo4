import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:practico2labo4/screens/screens.dart';
import 'package:practico2labo4/screens/visualizacion_movimiento_screen.dart';

class ListaMovimientosScreen extends StatefulWidget {
  const ListaMovimientosScreen({super.key});

  @override
  State<ListaMovimientosScreen> createState() => _ListaMovimientosScreenState();
}

class _ListaMovimientosScreenState extends State<ListaMovimientosScreen> {
  final TextEditingController searchController = TextEditingController();
  List<dynamic> movimientos = [];
  List<dynamic> filteredMovimientos = [];
  bool isLoading = false;
  String? nextUrl;
  bool isDisposed = false;
  String lastQuery = ''; // Almacena la última búsqueda realizada.

  @override
  void initState() {
    super.initState();
    fetchMovimientos('https://pokeapi.co/api/v2/move');
  }

  @override
  void dispose() {
    isDisposed = true;
    searchController.dispose();
    super.dispose();
  }

  Future<void> fetchMovimientos(String url, {int retries = 3}) async {
    setState(() {
      isLoading = true;
    });

    try {
      final response =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (!isDisposed) {
          setState(() {
            movimientos.addAll(data['results']);
            filteredMovimientos = List.from(movimientos);
            nextUrl = data['next'];
            isLoading = false;
          });
        }

        if (nextUrl != null && !isDisposed) {
          await fetchMovimientos(nextUrl!);
        }
      } else {
        throw Exception('Error al cargar los movimientos');
      }
    } on TimeoutException catch (_) {
      if (retries > 0) {
        await fetchMovimientos(url, retries: retries - 1);
      } else {
        setState(() {
          isLoading = false;
        });
        throw Exception(
            'Tiempo de espera agotado. No se pudo conectar a la API.');
      }
    } on http.ClientException catch (_) {
      if (retries > 0) {
        await fetchMovimientos(url, retries: retries - 1);
      } else {
        setState(() {
          isLoading = false;
        });
        throw Exception('Error de conexión. Verifica tu red o la API.');
      }
    }
  }

  void filterMovimientos(String query) {
    // Ignorar si la consulta es igual a la última realizada.
    if (query == lastQuery) return;

    // Actualizar lastQuery.
    lastQuery = query;

    // Si el texto es menor a 3 caracteres, no filtrar ni hacer peticiones.
    if (query.length < 3) {
      setState(() {
        filteredMovimientos = movimientos; // Restaurar la lista completa.
      });
      return;
    }

    // Filtrar resultados locales.
    setState(() {
      filteredMovimientos = movimientos
          .where((movimiento) =>
              movimiento['name'].toLowerCase().contains(query.toLowerCase()))
          .toList();
    });

    // Si no se encuentra nada en local, puedes agregar lógica para buscar en la API.
    if (filteredMovimientos.isEmpty) {
      fetchMovimientosForQuery(query);
    }
  }

  Future<void> fetchMovimientosForQuery(String query) async {
    // Construir la URL con el filtro de búsqueda (esto dependerá de la API).
    final url = 'https://pokeapi.co/api/v2/move?search=$query';

    try {
      final response =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (!isDisposed) {
          setState(() {
            filteredMovimientos = data['results'];
          });
        }
      } else {
        throw Exception('Error al buscar movimientos');
      }
    } on TimeoutException catch (_) {
      throw Exception('Tiempo de espera agotado. No se pudo conectar a la API.');
    } on http.ClientException catch (_) {
      throw Exception('Error de conexión. Verifica tu red o la API.');
    }
  }

  void clearSearch() {
    searchController.clear();
    filterMovimientos('');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de Movimientos'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Buscar movimientos...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: clearSearch,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              onChanged: filterMovimientos,
            ),
          ),
          Expanded(
            child: isLoading && movimientos.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: filteredMovimientos.length,
                    itemBuilder: (context, index) {
                      final movimiento = filteredMovimientos[index];

                      int pokemonId = index + 1;
                      String imageUrl = generatePokemonImageUrl(pokemonId);

                      return Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 15, vertical: 10),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.yellow.shade100,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              spreadRadius: 2,
                              offset: const Offset(4, 4),
                            ),
                          ],
                        ),
                        child: ListTile(
                          leading: Image.network(
                            imageUrl,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          ),
                          title: Text(
                            movimiento['name'].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios,
                              color: Colors.black54),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    VisualizacionMovimientoScreen(
                                  url: movimiento['url'],
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String generatePokemonImageUrl(int id) {
    return 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/$id.png';
  }
}


