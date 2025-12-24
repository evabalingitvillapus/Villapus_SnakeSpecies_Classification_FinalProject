import 'package:flutter/material.dart';
import '../models/snake_species_class.dart';

class ClassProvider extends ChangeNotifier {
  List<CactusClass> _classes = [];

  List<CactusClass> get classes => _classes;

  void loadClasses() {
    _classes = [
      CactusClass(
        name: 'Asian Vine Snake (Ahaetulla prasina)',
        description:
            'Slender, bright green, rear-fanged colubrid from SE Asia; excellent camouflage, hunts lizards, mildly venomous.',
        icon: Icons.grass,
        imagePath: 'assets/images/Asian Vine Snake.jpg',
      ),
      CactusClass(
        name: 'Banded Krait (Bungarus fasciatus)',
        description:
            'Highly venomous, black & yellow/white banded elapid from Asia; nocturnal, neurotoxic venom, triangular body.',
        icon: Icons.grass,
        imagePath: 'assets/images/Banded Krait.png',
      ),
      CactusClass(
        name: 'Blue Malayan Coral Snake (Calliophis bivirgatus)',
        description:
            'Striking blue/black body with red head/belly; highly venomous elapid, feeds on other snakes in SE Asia.',
        icon: Icons.local_florist,
        imagePath: 'assets/images/Blue Malayan Coral Snake.jpg',
      ),
      CactusClass(
        name: 'Eyelash Viper (Bothriechis schlegelii)',
        description:
            'Small, colorful New World pit viper; distinct "eyelashes" (modified scales) above eyes for protection/camouflage.',
        icon: Icons.grass,
        imagePath: 'assets/images/Eyelash Viper.png',
      ),
      CactusClass(
        name: 'Gaboon Viper (Bitis gabonica)',
        description:
            'Large, heavily patterned African viper; massive fangs, incredibly potent venom, masters of camouflage.',
        icon: Icons.nature,
        imagePath: 'assets/images/Gaboon Viper.png',
      ),
      CactusClass(
        name: 'Green Tree Python  (Morelia viridis)',
        description: 'Bright green, arboreal python from New Guinea/Australia; coiled ambush predator of birds/rodents.',
        icon: Icons.grass,
        imagePath: 'assets/images/Green Tree Python.jpg',
      ),
      CactusClass(
        name: 'Horned Viper (Cerastes cerastes)',
        description: 'Desert viper from North Africa/Middle East; distinguished by single or double horns above eyes, often buries in sand.',
        icon: Icons.grass,
        imagePath: 'assets/images/Horned Viper.png',
      ),
      CactusClass(
        name: 'King Brown Snake (Pseudechis australis)',
        description: 'Large, highly venomous Australian snake; potent venom, broad diet, often brown/yellow.',
        icon: Icons.local_florist,
        imagePath: 'assets/images/King Brown Snake.jpeg',
      ),
      CactusClass(
        name: 'Rainbow Boa (Epicrates cenchria)',
        description:
            'South American boa; iridescent scales that shimmer with rainbow colors; constrictor, arboreal/terrestrial.',
        icon: Icons.nature,
        imagePath: 'assets/images/Rainbow Boa.jpg',
      ),
      CactusClass(
        name: 'Sri Lankan Cat Snake (Boiga ceylonensis)',
        description:
            'Camouflaged, mildly venomous cat snake from Sri Lanka; nocturnal, hunts lizards/frogs in trees. ',
        icon: Icons.grass,
        imagePath: 'assets/images/Sri Lankan Cat Snake.png',
      ),
    ];
    notifyListeners();
  }
}
