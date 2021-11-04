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

@available(OSX 10.15, iOS 13, tvOS 13, watchOS 6, *)
extension Publisher {

	/// Creates a new `Publisher` that will multicast values emitted by
	/// the Upstream, up to `capacity`.
	/// This means that all clients of this Publisher will see the same
	/// version of the emitted values/errors/completions.
	///
	/// The upstream publishers will not be connected until subscription of the
	/// first downstream subscriber. When subscribing to this publisher, all
	/// previous values (up to `capacity`) will be emitted, followed by any new
	/// values.
	///
	/// - parameters:
	///   - capacity: Number of values to hold.
	///
	/// - returns: A multicast publisher that will hold up to last `capacity` values.
	public func replayLazily(
		upTo capacity: Int = 0
	) -> Publishers.Autoconnect<Publishers.Multicast<Self, ReplaySubject<Output, Failure>>> {
		multicast { ReplaySubject( bufferSize: capacity ) }.autoconnect()
	}
}
