//
//  ProductService.swift
//  tableview-binding
//
//  Created by Kelvin Fok on 6/12/22.
//

import Foundation

protocol ProductService {
  func fetchProducts() async -> [Product]
}

class ProductServiceImp: ProductService {
  func fetchProducts() async -> [Product] {
    try? await Task.sleep(nanoseconds: 1 * 1_000_000_000) // 1 second
    return Product.collection
  }
}
