//
//  -=Combine Extensions=-
//
// MIT License
//
// Copyright (c) 2019-present Vladimir Kazantsev
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

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
	public func store( cancellable: AnyCancellable, with id: String? = nil ) {
		token?.append( cancellable, id: id )
	}

	/// Add the given cancellable as an observer of `self`.
	///
	/// - parameters:
	///   - cancellable: The cancellable to be disposed of when `self` ends.
	public static func += ( lifetime: Lifetime, cancellable: AnyCancellable ) {
		lifetime.store( cancellable: cancellable )
	}

	/// Observe the termination of `self`.
	///
	/// - parameters:
	///   - action: The action to be invoked when `self` ends.
	public func observeEnded( id: String? = nil, _ action: @escaping () -> Void ) {
		token?.appendFirst( AnyCancellable( action ), id: id )
	}

	/// Observe the termination of `self`.
	///
	/// - parameters:
	///   - action: The action to be invoked when `self` ends.
	public static func += ( lifetime: Lifetime, action: @escaping () -> Void ) {
		lifetime.observeEnded( action )
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
	/// Check if there is a cancellable with `id` identificator.
	///
	/// - parameter id: Id of a cancellable to search.
	func contains( id: String ) -> Bool {
		token?.contains( id: id ) ?? false
	}

	/// Removes cancellable with `id` identificator.
	/// Does nothing if cancellable with this identificator is not found.
	///
	/// - parameter id: Id of a cancellable to remove.
	func remove( id: String ) {
		token?.remove( id: id )
	}
}

@available(OSX 10.15, iOS 13, tvOS 13, watchOS 6, *)
extension AnyCancellable {

	/// Stores this type-erasing cancellable instance in the specified collection.
	///
	/// - Parameter collection: The collection in which to store this ``AnyCancellable``.
	public func store( in lifetime: Lifetime, id: String? = nil ) {
		lifetime.store( cancellable: self, with: id )
	}
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

		init( cancellable: AnyCancellable? = nil, id: String? = nil ) {
			if let cancellable = cancellable {
				append( cancellable, id: id )
			}
		}

		public func cancel() {
			isCancelled = true
			let copy = cancellables
			copy.forEach { $0.cancellable.cancel() }
			cancellables.removeAll()
		}

		fileprivate func contains( id: String ) -> Bool {
			os_unfair_lock_lock( &lock ); defer { os_unfair_lock_unlock( &lock ) }
			return cancellables.contains { $0.id == id }
		}

		fileprivate func remove( id: String ) {
			os_unfair_lock_lock( &lock ); defer { os_unfair_lock_unlock( &lock ) }
			if let index = cancellables.firstIndex( where: { $0.id == id } ) {
				cancellables.remove( at: index )
			}
		}

		fileprivate func append( _ cancellable: AnyCancellable, id: String? = nil ) {
			os_unfair_lock_lock( &lock ); defer { os_unfair_lock_unlock( &lock ) }
			cancellables.append( (id ?? randomId(), cancellable) )
		}
		fileprivate func appendFirst( _ cancellable: AnyCancellable, id: String? = nil ) {
			os_unfair_lock_lock( &lock ); defer { os_unfair_lock_unlock( &lock ) }
			cancellables.insert( (id ?? randomId(), cancellable), at: 0 )
		}

		deinit { cancel() }

		private typealias Value = ( id: String, cancellable: AnyCancellable )

		private var lock = os_unfair_lock()
		private var cancellables = Array<Value>()
		fileprivate var isCancelled: Bool = false

		private func randomId() -> String { UUID().uuidString }
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
