//
//  EnsurePublisher.swift
//
//  Created by Vladimir Kazantsev on 04.02.2020.
//  Copyright © 2020 MC2Soft. All rights reserved.
//

#if canImport( Combine )
import Foundation
import Combine

@available(OSX 10.15, iOS 13, tvOS 13, watchOS 6, *)
public extension Publisher {

	/// Performs the specified closures when `receiveOutput` or `receiveCompletion` events received.
	///
	/// - Parameters:
	///   - ensureExecution: A closure that executes when the publisher receives `receiveOutput`
	///  or `receiveCompletion` events.
	/// - Returns: A publisher that performs the specified closure when publisher events occur.
	func ensure( ensureExecution: @escaping () -> Void ) -> Publishers.HandleEvents<Self> {
		return handleEvents( receiveOutput: { _ in ensureExecution() },
							 receiveCompletion: { _ in ensureExecution() } )
	}
}
#endif
