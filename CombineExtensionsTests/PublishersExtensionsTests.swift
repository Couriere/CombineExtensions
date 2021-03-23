//
//  PublishersExtensionsTests.swift
//  CombineExtensionsTests
//
//  Created by Vladimir Kazantsev on 09.03.2021.
//  Copyright © 2021 MC2 Software. All rights reserved.
//

import XCTest
import Combine
import CombineExtensions

@available(OSX 10.15, iOS 13, tvOS 13, watchOS 6, *)
class PublishersExtensionsTests: XCTestCase {

	var cancellable: AnyCancellable?

	func createPublisher( delay milliseconds: Int ) -> AnyPublisher<Int, Error> {
		Just( milliseconds )
			.delay( for: .milliseconds( milliseconds ), scheduler: RunLoop.main )
			.setFailureType( to: Error.self )
			.eraseToAnyPublisher()
	}

	func testZipPublishersArray() {

		let completionExpectation = expectation( description: "Completion has been received" )
		let resultExpectation = expectation( description: "Result has been received" )

		cancellable = Publishers.Zip( [
			createPublisher(delay: 1000),
			createPublisher(delay: 20),
			createPublisher(delay: 1500),
			createPublisher(delay: 1200)
		])
		.sink( receiveCompletion: {
			if case .finished = $0 { completionExpectation.fulfill() }
			else { XCTAssert( false, "Received unexpected error" ) }
		}, receiveValue: { results in
			XCTAssertEqual( results, [ 1000, 20, 1500, 1200 ] )
			resultExpectation.fulfill()
		})

		wait( for: [ resultExpectation, completionExpectation ], timeout: 2000 )
	}

	func testZipPublishersArrayFailure() {

		let failureExpectation = expectation( description: "Error has been received" )

		let failurePublisher = Just( 200 )
			.delay( for: .milliseconds( 200 ), scheduler: RunLoop.main )
			.setFailureType( to: Error.self )
			.flatMap { _ in Fail<Int, Error>(error: NSError( domain: "", code: -1, userInfo: nil )) }
			.eraseToAnyPublisher()


		cancellable = Publishers.Zip( [
			createPublisher( delay: 1000 ),
			failurePublisher,
			createPublisher( delay: 1500 ),
			createPublisher( delay: 1200 )
		])
		.sink( receiveCompletion: {
			if case .finished = $0 { XCTAssert( false, "Received unexpected completion" ) }
			else { failureExpectation.fulfill() }
		}, receiveValue: { results in
			XCTAssert( false, "Received unexpected result" )
		})

		wait( for: [ failureExpectation ], timeout: 300 )
	}
}
