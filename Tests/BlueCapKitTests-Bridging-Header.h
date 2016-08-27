//
//  BlueCapKitTests-Bridging-Header.h
//  BlueCapKitTests
//
//  Created by Troy Stribling on 8/27/16.
//  Copyright © 2016 Troy Stribling. All rights reserved.
//

#ifndef BlueCapKitTests_Bridging_Header_h
#define BlueCapKitTests_Bridging_Header_h

// Returns the current running test so that XCTAsserts can reference it.
@class XCTestCase;
extern XCTestCase *_XCTCurrentTestCase();

#endif /* BlueCapKitTests_Bridging_Header_h */
