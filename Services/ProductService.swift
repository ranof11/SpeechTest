//
//  ProductService.swift
//  SpeechTest
//
//  Created by Rajesh Triadi Noftarizal on 03/03/25.
//

import Foundation

class ProductService {
    static let shared = ProductService()
    
    let products: [Product] = [
        Product(name: "Notebook", sales: 100, date: createDate(year: 2024, month: 1, day: 10)),
        Product(name: "Printer", sales: 150, date: createDate(year: 2024, month: 1, day: 22)),
        Product(name: "Desk Chair", sales: 80, date: createDate(year: 2024, month: 3, day: 5)),
        Product(name: "Monitor", sales: 200, date: createDate(year: 2024, month: 3, day: 18)),
        Product(name: "Paper Ream", sales: 120, date: createDate(year: 2024, month: 5, day: 7)),
        Product(name: "Notebook", sales: 140, date: createDate(year: 2025, month: 1, day: 5)),
        Product(name: "Printer", sales: 170, date: createDate(year: 2025, month: 1, day: 18)),
        Product(name: "Monitor", sales: 230, date: createDate(year: 2025, month: 3, day: 25)),
        Product(name: "Desk Chair", sales: 205, date: createDate(year: 2025, month: 11, day: 6))
    ]
}

private func createDate(year: Int, month: Int, day: Int) -> Date {
    return Calendar.current.date(from: DateComponents(year: year, month: month, day: day))!
}
