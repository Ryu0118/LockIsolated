import XCTest
@testable import LockIsolated

final class LockIsolatedTests: XCTestCase {
    func testExample() throws {
        // XCTest Documenation
        // https://developer.apple.com/documentation/xctest

        // Defining Test Cases and Test Methods
        // https://developer.apple.com/documentation/xctest/defining_test_cases_and_test_methods

        let hoge = Hoge()
        Hoge.swizzling()
        for i in 0...100 {
            Task.detached {
                hoge.decrement(1)
            }
//            Task.detached {
//                hoge.decrement()
//            }
        }
    }
}
