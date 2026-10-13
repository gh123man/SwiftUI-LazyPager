import XCTest
import SwiftUI
@testable import LazyPager

final class LazyPagerTests: XCTestCase {
    @MainActor
    func testClearingDataDuringScroll() async {
        for decelerates in [false, true] {
            var events: [Bool] = []
            var config = Config<Int>()
            config.scrollActiveCallback = { events.append($0) }
            let provider = ViewDataProvider(data: [0, 1, 2], page: .constant(0), config: config) { Text("\($0)") }
            let loaded = expectation(description: "Initial pages loaded")
            DispatchQueue.main.async { loaded.fulfill() }
            await fulfillment(of: [loaded], timeout: 2)
            let pager = provider.pagerView
            XCTAssertFalse(pager.loadedViews.isEmpty)
            pager.scrollViewWillBeginDragging(pager)
            provider.data = []
            provider.reloadViews()
            XCTAssertTrue(pager.loadedViews.isEmpty)
            pager.scrollViewDidScroll(pager)
            pager.scrollViewDidEndDragging(pager, willDecelerate: decelerates)
            if decelerates {
                XCTAssertEqual(events, [true])
                pager.scrollViewDidEndDecelerating(pager)
            }
            XCTAssertEqual(events, [true, false])
            XCTAssertEqual(pager.currentIndex, 0)
        }
    }

    @MainActor
    func testInitiallyEmptyPagerReceivesScrollCallbacks() {
        let provider = ViewDataProvider(data: [Int](), page: .constant(0), config: Config<Int>()) { Text("\($0)") }
        provider.pagerView.scrollViewDidScroll(provider.pagerView)
        provider.pagerView.scrollingFinished()
        XCTAssertTrue(provider.pagerView.loadedViews.isEmpty)
        XCTAssertEqual(provider.pagerView.currentIndex, 0)
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
//        XCTAssertEqual(LazyPager().text, "Hello, World!")
    }
}
