//
//  tableview_bindingTests.swift
//  tableview-bindingTests
//
//  Created by Kelvin Fok on 6/12/22.
//

import XCTest
import Combine
@testable import tableview_binding

final class tableview_bindingTests: XCTestCase {

  private var sut: ViewModel!
  private var productService: ProductServiceMock!
  
  private let vcOutput = PassthroughSubject<ViewModel.Input, Never>()
  private var cancellables = Set<AnyCancellable>()
  
  override func setUp() {
    productService = ProductServiceMock()
    sut = .init(productService: productService)
    super.setUp()
  }
  
  override func tearDown() {
    productService = nil
    sut = nil
    super.tearDown()
  }
  
  // Test scenarios
  // 1. When view did load happens, fetch product api is called ✅
  // 2. When fetch product happens successfully, vc's views are updated ✅
  // 3. When an item is added to cart, vc's cart quantity & cost are updated ✅
  // 4. when item is liked, heart button is shown
  // 5. when fetch product api returns empty array (2xx status code), vc's tableview shows recommendation to buy other products
  // 6. when fetch product api fails (4xx status code), vc's shows some error message and allow user to retry
  
  func _testFetchProducts_onViewDidLoad_isCalled() {
    // given
    let vmOutput = sut.transform(input: vcOutput.eraseToAnyPublisher())
    let expectation = XCTestExpectation(description: "fetch products called")
    // when
    vmOutput.sink { event in }.store(in: &cancellables)
    productService.expectation = expectation
    vcOutput.send(.viewDidLoad)
    // then
    wait(for: [expectation], timeout: 1.0)
    XCTAssertEqual(productService.fetchProductsCallCounter, 1)
  }
  
  func testSetProductsAndUpdateView_onSuccessfulFetchProductsCall_isCalled() {
    // given
    let vmOutput = sut.transform(input: vcOutput.eraseToAnyPublisher())
    productService.mockedValues = [
      .init(name: "Apple", imageName: "apple.fill", price: 10, id: 1),
      .init(name: "Orange", imageName: "orange.fill", price: 20, id: 2),
      .init(name: "Durian", imageName: "orange.fill", price: 20, id: 2)
    ]
    let expectation = XCTestExpectation(description: "set products called")
    let expectation2 = XCTestExpectation(description: "update view called")
    // then
    vmOutput.sink { event in
      switch event {
      case let .setProducts(products):
        expectation.fulfill()
        XCTAssertEqual(products.count, 3)
        XCTAssertEqual(products[0].name, "Apple")
        XCTAssertEqual(products[0].imageName, "apple.fill")
        XCTAssertEqual(products[0].price, 10)
      case let .updateView(numberOfItemsInCart, totalCost, likedProductIds, productQuantities):
        expectation2.fulfill()
        XCTAssertEqual(numberOfItemsInCart, 0)
        XCTAssertEqual(totalCost, 0)
        XCTAssertEqual(likedProductIds, Set([]))
        XCTAssertEqual(productQuantities, [:])
      }
    }.store(in: &cancellables)
    // when
    vcOutput.send(.viewDidLoad)
    wait(for: [expectation, expectation2], timeout: 0.5)
  }
  
  func _testUpdateView_whenProductAddedToCart_isCalled() {
    // given
    let vmOutput = sut.transform(input: vcOutput.eraseToAnyPublisher())
    let selectedProduct = Product(name: "Apple", imageName: "apple.fill", price: 11, id: 1)
    productService.mockedValues = [
      selectedProduct,
      .init(name: "Orange", imageName: "orange.fill", price: 2, id: 2)
    ]
    // then
    vmOutput.sink { event in
      if case let .updateView(numberOfItemsInCart, totalCost, likedProductIds, productQuantities) = event {
        XCTAssertEqual(numberOfItemsInCart, 5)
        XCTAssertEqual(totalCost, 55)
        XCTAssertTrue(likedProductIds.isEmpty)
        XCTAssertEqual(productQuantities[selectedProduct.id], 5)
      } else {
        XCTFail("expecting updateView")
      }
    }.store(in: &cancellables)
    // when
    vcOutput.send(.onProductCellEvent(event: .quantityDidChange(value: 5), product: selectedProduct))
  }
}

class ProductServiceMock: ProductService {
  var mockedValues: [Product] = []
  var fetchProductsCallCounter = 0
  var expectation: XCTestExpectation?
  
  func fetchProducts() async -> [Product] {
    expectation?.fulfill()
    fetchProductsCallCounter += 1
    return mockedValues
  }
}
