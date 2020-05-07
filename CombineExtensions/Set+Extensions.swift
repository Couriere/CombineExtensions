//
//  Set+Extensions.swift
//
//  Created by Vladimir Kazantsev on 12.12.2019.
//  Copyright © 2019 MC2Soft. All rights reserved.
//

import Foundation

public extension Set {
	static func +=( set: inout Set, value: Element ) {
		set.insert( value )
	}
	static func -=( set: inout Set, value: Element ) {
		set.remove( value )
	}
}
