import Foundation
import SwiftData

enum FoodCatalogSeeder {
    static let foods: [(name: String, category: String)] = [
        ("Huevo", "Proteínas"),
        ("Pollo", "Proteínas"),
        ("Res", "Proteínas"),
        ("Pescado", "Proteínas"),
        ("Atún", "Proteínas"),
        ("Cerdo", "Proteínas"),
        ("Arroz", "Carbohidratos"),
        ("Pasta", "Carbohidratos"),
        ("Pan", "Carbohidratos"),
        ("Tortilla", "Carbohidratos"),
        ("Avena", "Carbohidratos"),
        ("Papa", "Carbohidratos"),
        ("Frijoles", "Legumbres"),
        ("Lentejas", "Legumbres"),
        ("Garbanzos", "Legumbres"),
        ("Aguacate", "Grasas saludables"),
        ("Queso", "Lácteos"),
        ("Yogur", "Lácteos"),
        ("Leche", "Lácteos"),
        ("Crema", "Lácteos"),
        ("Tomate", "Verduras"),
        ("Cebolla", "Verduras"),
        ("Lechuga", "Verduras"),
        ("Espinaca", "Verduras"),
        ("Zanahoria", "Verduras"),
        ("Brócoli", "Verduras"),
        ("Chile", "Verduras"),
        ("Calabaza", "Verduras"),
        ("Manzana", "Frutas"),
        ("Plátano", "Frutas"),
        ("Naranja", "Frutas"),
        ("Fresa", "Frutas"),
        ("Uva", "Frutas"),
        ("Mango", "Frutas"),
        ("Piña", "Frutas"),
        ("Papaya", "Frutas"),
        ("Café", "Bebidas"),
        ("Té", "Bebidas"),
        ("Agua", "Bebidas"),
        ("Jugo", "Bebidas"),
        ("Aceite de oliva", "Grasas saludables"),
        ("Mantequilla", "Grasas saludables"),
        ("Sal", "Condimentos"),
        ("Pimienta", "Condimentos"),
        ("Comino", "Condimentos"),
        ("Cilantro", "Condimentos"),
        ("Mayonesa", "Salsas"),
        ("Mostaza", "Salsas"),
        ("Salsa de tomate", "Salsas"),
        ("Vinagre", "Condimentos"),
    ]

    static func seedIfNeeded(in context: ModelContext) {
        let descriptor = FetchDescriptor<SDFoodItem>()
        let count = (try? context.fetchCount(descriptor)) ?? 0
        guard count == 0 else { return }

        for food in foods {
            let item = SDFoodItem(
                name: food.name,
                category: food.category,
                source: "local"
            )
            context.insert(item)
        }
        try? context.save()
    }
}
