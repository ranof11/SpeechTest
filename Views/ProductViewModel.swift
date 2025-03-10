//
//  ProductViewModel.swift
//  SpeechTest
//
//  Created by Rajesh Triadi Noftarizal on 28/02/25.
//

import Foundation

class ProductViewModel: ObservableObject {
    @Published var displayedProducts: [Product] = []

    init() {
        resetProducts()
    }
    
    func fetchProducts(type: String? = nil, count: Int? = nil, month: Int? = nil, year: Int? = nil) {
        let calendar = Calendar.current
        var filteredProducts = ProductService.shared.products
        
        if let year = year {
            filteredProducts = filteredProducts.filter {
                calendar.component(.year, from: $0.date) == year
            }
        }
        
        if let month = month {
            filteredProducts = filteredProducts.filter {
                calendar.component(.month, from: $0.date) == month
            }
        }
        
        if let type = type, let count = count {
            filteredProducts = filteredProducts.sorted {
                type == "top" ? $0.sales > $1.sales : $0.sales < $1.sales
            }
            displayedProducts = Array(filteredProducts.prefix(count))
        } else {
            displayedProducts = filteredProducts.sorted { $0.date > $1.date }
        }
    }
    
    func resetProducts() {
        displayedProducts = ProductService.shared.products.sorted { $0.date > $1.date }
    }
}
