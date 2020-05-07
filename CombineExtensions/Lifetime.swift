//
//  Combine+Lifetime.swift
//
//  Created by Vladimir Kazantsev on 05.02.2020.
//  Copyright © 2020 MC2Soft. All rights reserved.
//

import Foundation
import Combine

/// Represents the lifetime of an object, and provides a hook to observe when
/// the object deinitializes.
@available(OSX 10.15, iOS 13, tvOS 13, watchOS 6, *)
public final class Lifetime {

	/// Add the given cancellable as an observer of `self`.
	///
	/// - parameters:
	///   - cancellable: The cancellable to be disposed of when `self` ends.
	public static func += ( lifetime: Lifetime, cancellable: AnyCancellable ) {
		lifetime.token?.cancellables.append( cancellable )
	}

	/// Observe the termination of `self`.
	///
	/// - parameters:
	///   - action: The action to be invoked when `self` ends.
	public static func += ( lifetime: Lifetime, action: @escaping () -> Void ) {
		lifetime.token?.cancellables.insert( AnyCancellable( action ), at: 0 )
	}

	/// Observe the termination of `self`.
	///
	/// - parameters:
	///   - action: The action to be invoked when `self` ends.
	public func observeEnded( _ action: @escaping () -> Void ) {
		token?.cancellables.insert( AnyCancellable( action ), at: 0 )
	}

	/// A flag indicating whether the lifetime has ended.
	public var hasEnded: Bool {
		return token?.isCancelled ?? true
	}

	public init( _ token: Token ) {
		self.token = token
	}

	private weak var token: Token?
}

@available(OSX 10.15, iOS 13, tvOS 13, watchOS 6, *)
public extension Lifetime {
	/// Factory method for creating a `Lifetime` and its associated `Token`.
	///
	/// - returns: A `(lifetime, token)` tuple.
	static func make() -> ( lifetime: Lifetime, token: Token ) {
		let token = Token()
		return ( Lifetime( token ), token )
	}

	/// A `Lifetime` that has already ended.
	static var empty: Lifetime = {
		let ( lifetime, _ ) = Lifetime.make()
		return lifetime
	}()

	/// A `Lifetime` thet never ends.
	static var persistent: Lifetime = {
		Lifetime( persistentToken )
	}()
	private static let persistentToken = Token()

}

@available(OSX 10.15, iOS 13, tvOS 13, watchOS 6, *)
public extension Lifetime {
	/// A token object which completes its associated `Lifetime` when
	/// it deinitializes, or when `cancel()` is called.
	///
	/// It is generally used in conjuncion with `Lifetime` as a private
	/// deinitialization trigger.
	///
	/// ```
	/// class MyController {
	///		private let (lifetime, token) = Lifetime.make()
	/// }
	/// ```
	final class Token {

		init( cancellable: AnyCancellable? = nil ) {
			if let cancellable = cancellable {
				cancellables = [ cancellable ]
			}
		}

		public func cancel() {
			isCancelled = true
			cancellables.forEach { $0.cancel() }
			cancellables.removeAll()
		}

		deinit { cancel() }

		fileprivate var cancellables = Array<AnyCancellable>()
		fileprivate var isCancelled: Bool = false
	}
}

@available(OSX 10.15, iOS 13, tvOS 13, watchOS 6, *)
public extension Lifetime {

	/// Returns lifetime of given object.
	/// The lifetime ends when the given object is deinitialized.
	///
	/// - parameters:
	///   - object: The object for which the lifetime is obtained.
	///
	/// - returns: The lifetime that ends when the given object is deinitialized.
	static func of( _ object: AnyObject ) -> Lifetime {

		if let lifetime = objc_getAssociatedObject( object, &lifeTimeOfObjectKey ) as? Lifetime {
			return lifetime
		}

		let ( lifetime, token ) = Lifetime.make()

		objc_setAssociatedObject( object, &lifeTimeOfObjectKey, lifetime, .OBJC_ASSOCIATION_RETAIN )
		objc_setAssociatedObject( object, &lifeTimeTokenOfObjectKey, token, .OBJC_ASSOCIATION_RETAIN )

		return lifetime
	}
}

@available(OSX 10.15, iOS 13, tvOS 13, watchOS 6, *)
public extension Reactive where Base: AnyObject {
	/// Returns a lifetime that ends when the object is deallocated.
	@nonobjc var lifetime: Lifetime {
		return .of( base )
	}
}


private var lifeTimeOfObjectKey: String = "lifeTimeOfObjectKey"
private var lifeTimeTokenOfObjectKey: String = "lifeTimeTokenOfObjectKey"
