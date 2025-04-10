import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:rickandmortyapp/providers/api_provider.dart';
import 'package:rickandmortyapp/widgets/search_delegate.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final scrollController = ScrollController();
  final pageController = PageController(viewportFraction: 0.8);
  bool isLoading = false;
  int page = 1;
  int currentPage = 0;

  @override
  void initState() {
    super.initState();
    final apiProvider = Provider.of<ApiProvider>(context, listen: false);
    apiProvider.getCharacters(page);
    scrollController.addListener(() async {
      if (scrollController.position.pixels ==
          scrollController.position.maxScrollExtent) {
        setState(() {
          isLoading = true;
        });
        page++;
        await apiProvider.getCharacters(page);
        setState(() {
          isLoading = false;
        });
      }
    });

    // Auto-scroll del carrusel
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _autoScroll();
      }
    });
  }

  void _autoScroll() {
    if (currentPage <
        (Provider.of<ApiProvider>(context, listen: false).characters.length -
            1)) {
      currentPage++;
    } else {
      currentPage = 0;
    }
    pageController.animateToPage(
      currentPage,
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOut,
    );
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _autoScroll();
      }
    });
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final apiProvider = Provider.of<ApiProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Portal App',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
              onPressed: () {
                showSearch(context: context, delegate: SearchCharacter());
              },
              icon: const Icon(Icons.search))
        ],
      ),
      body: SizedBox(
        height: double.infinity,
        width: double.infinity,
        child: apiProvider.characters.isNotEmpty
            ? Column(
                children: [
                  // Carrusel de personajes
                  SizedBox(
                    height: 300,
                    child: PageView.builder(
                      controller: pageController,
                      onPageChanged: (index) {
                        setState(() {
                          currentPage = index;
                        });
                      },
                      itemCount: apiProvider.characters.length,
                      itemBuilder: (context, index) {
                        final character = apiProvider.characters[index];
                        return GestureDetector(
                          onTap: () =>
                              context.push('/character', extra: character),
                          child: Container(
                            margin:
                                const EdgeInsets.symmetric(horizontal: 10.0),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              image: DecorationImage(
                                image: NetworkImage(character.image ?? ''),
                                fit: BoxFit.cover,
                              ),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.8),
                                  ],
                                ),
                              ),
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    character.name ?? 'Unknown',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    character.species ?? 'Unknown',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Lista de personajes
                  Expanded(
                    child: CharacterList(
                      apiProvider: apiProvider,
                      isLoading: isLoading,
                      scrollController: scrollController,
                    ),
                  ),
                ],
              )
            : const Center(
                child: CircularProgressIndicator(),
              ),
      ),
    );
  }
}

class CharacterList extends StatelessWidget {
  const CharacterList(
      {super.key,
      required this.apiProvider,
      required this.scrollController,
      required this.isLoading});

  final ApiProvider apiProvider;
  final ScrollController scrollController;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.87,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
      ),
      itemCount: isLoading
          ? apiProvider.characters.length + 2
          : apiProvider.characters.length,
      controller: scrollController,
      itemBuilder: (context, index) {
        if (index < apiProvider.characters.length) {
          final character = apiProvider.characters[index];
          return GestureDetector(
            onTap: () {
              context.go('/character', extra: character);
            },
            child: Card(
              child: Column(
                children: [
                  Hero(
                    tag: character.id!,
                    child: FadeInImage(
                      placeholder: const AssetImage('assets/images/portal.gif'),
                      image: NetworkImage(character.image!),
                    ),
                  ),
                  Text(
                    character.name!,
                    style: const TextStyle(
                      fontSize: 16,
                      overflow: TextOverflow.ellipsis,
                    ),
                  )
                ],
              ),
            ),
          );
        } else {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
      },
    );
  }
}
