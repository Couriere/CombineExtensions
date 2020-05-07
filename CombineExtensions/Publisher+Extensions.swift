//
//  Publisher+Extensions.swift
//  MegafonTV
//
//  Created by Vladimir Kazantsev on 06.04.2020.
//  Copyright © 2020 MC2Soft. All rights reserved.
//

import Foundation
import Combine

@available(OSX 10.15, iOS 13, tvOS 13, watchOS 6, *)
public extension Publisher {

	/// Forward events from `self` with history: values of the returned signal
	/// are a tuples whose first member is the previous value and whose second member
	/// is the current value. `initial` is supplied as the first member when `self`
	/// sends its first value.
	///
	/// - parameters:
	///   - initial: A value that will be combined with the first value sent by
	///              `self`.
	///
	/// - returns: A signal that sends tuples that contain previous and current
	///            sent values of `self`.
	func combinePrevious( initial: Output ) ->  Publishers.Scan<Self, ( Output, Output )> {
		return self.scan( ( initial, initial ) ) { ( $0.1, $1 ) }
	}
}

@available(OSX 10.15, iOS 13, tvOS 13, watchOS 6, *)
public extension Publisher where Self.Failure == Never {
	/// Assigns each element from a Publisher to a property on an object.
	///
	/// - Parameters:
	///   - keyPath: The key path of the property to assign.
	///   - object: The object on which to assign the value.
	/// - returns: A cancellable instance; used when you end assignment of the received value.
	/// Deallocation of the result will tear down the subscription stream.
	/// - note: Unlike `assign(to:on:)` object captured weakly, allowing it to deallocate
	/// without needing to cancel cancellable instance.
	func assignUnretained<Root: AnyObject>( to keyPath: ReferenceWritableKeyPath<Root, Self.Output>,
												   on object: Root ) -> AnyCancellable {
		self.sink { [weak object] in object?[ keyPath: keyPath ] = $0 }
	}
}
