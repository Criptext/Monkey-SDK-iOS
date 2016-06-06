//
//  NSData+Compression.h
//  MonkeyKit
//
//  Created by Gianni Carlo on 5/31/16.
//  Copyright © 2016 Criptext. All rights reserved.
//

#import <Foundation/NSData.h>

@interface NSData (Compression)

#pragma mark -
#pragma mark Zlib Compression routines
/*! Returns a data object containing a Zlib decompressed copy of the receivers contents.
 * \returns A data object containing a Zlib decompressed copy of the receivers contents.
 */
- (NSData *) mok_zlibInflate;
/*! Returns a data object containing a Zlib compressed copy of the receivers contents.
 * \returns A data object containing a Zlib compressed copy of the receivers contents.
 */
- (NSData *) mok_zlibDeflate;

#pragma mark -
#pragma mark Gzip Compression routines
/*! Returns a data object containing a Gzip decompressed copy of the receivers contents.
 * \returns A data object containing a Gzip decompressed copy of the receivers contents.
 */
- (NSData *) mok_gzipInflate;
/*! Returns a data object containing a Gzip compressed copy of the receivers contents.
 * \returns A data object containing a Gzip compressed copy of the receivers contents.
 */
- (NSData *) mok_gzipDeflate;

@end