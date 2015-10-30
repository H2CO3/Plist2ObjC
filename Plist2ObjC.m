/*
 * Plist2ObjC.m
 * Plist2ObjC
 *
 * Created by Arpad Goretity on 24/10/2012
 * Licensed under the 3-clause BSD License
 */

#import <stdio.h>
#import <Foundation/Foundation.h>


#define INDENT_STRING @"\t"

NSString *generateIndent(NSInteger level)
{
	NSMutableString *s = [NSMutableString new];

	for (NSInteger i = 0; i < level; i++) {
		[s appendString:INDENT_STRING];
	}

	return s;
}

NSString *removeIndentation(NSString *str)
{
	NSInteger len = [str length];
	NSInteger i;
	NSInteger idx = len;
	for (i = 0; i < len; i++) {
		NSString *s = [str substringWithRange:NSMakeRange(i, 1)];
		if ([s isEqualToString:@"\t"] == NO) {
			idx = i;
			break;
		}
	}

	return [str substringFromIndex:idx];
}

NSString *escape(NSString *str)
{
	NSDictionary *replacements = @{
		@"\"": @"\\\"",
		@"\\": @"\\\\",
		@"\'": @"\\\'",
		@"\n": @"\\n",
		@"\r": @"\\r",
		@"\t": @"\\t"
	};

	for (NSString *key in replacements) {
		str = [str stringByReplacingOccurrencesOfString:key withString:replacements[key]];
	}

	return str;
}

@protocol Plist2ObjC_Dumpable
- (NSString *)recursiveDump:(NSInteger)level;
@end

@interface NSString (Plist2ObjC) <Plist2ObjC_Dumpable>
@end

@interface NSNumber (Plist2ObjC) <Plist2ObjC_Dumpable>
@end

@interface NSArray (Plist2ObjC) <Plist2ObjC_Dumpable>
@end

@interface NSDictionary (Plist2ObjC) <Plist2ObjC_Dumpable>
@end

@interface NSData (Plist2ObjC) <Plist2ObjC_Dumpable>
@end

@interface NSDate (Plist2ObjC) <Plist2ObjC_Dumpable>
@end

@implementation NSString (Plist2ObjC)

- (NSString *)recursiveDump:(NSInteger)level {
	return [NSString stringWithFormat:@"%@@\"%@\"",
	                 generateIndent(level),
	                 escape(self)
	       ];
}

@end

@implementation NSNumber (Plist2ObjC)

- (NSString *)recursiveDump:(NSInteger)level {
	return [NSString stringWithFormat:@"%@@%@", generateIndent(level), self];
}

@end

@implementation NSArray (Plist2ObjC)

- (NSString *)recursiveDump:(NSInteger)level {
	NSString *selfIndent = generateIndent(level);
	NSString *childIndent = [selfIndent stringByAppendingString:INDENT_STRING];
	NSMutableString *str = [NSMutableString stringWithString:@"@[\n"];

	for (NSInteger i = 0; i < self.count; i++) {
		if (i > 0) {
			[str appendString:@",\n"];
		}

		[str appendFormat:@"%@%@",
		     childIndent,
		     removeIndentation([self[i] recursiveDump:level + 1])
		];
	}

	[str appendFormat:@"\n%@]", selfIndent];
	return str;
}

@end

@implementation NSDictionary (Plist2ObjC)

- (NSString *)recursiveDump:(NSInteger)level {
	NSString *selfIndent = generateIndent(level);
	NSString *childIndent = [selfIndent stringByAppendingString:INDENT_STRING];
	NSMutableString *str = [NSMutableString stringWithString:@"@{\n"];
	NSArray *keys = self.allKeys;

	for (NSInteger i = 0; i < keys.count; i++) {
		if (i > 0) {
			[str appendString:@",\n"];
		}

		NSString *key = keys[i];
		[str appendFormat:@"%@%@: %@",
		     childIndent,
		     removeIndentation([key recursiveDump:level + 1]),
		     removeIndentation([self[key] recursiveDump:level + 1])
		];
	}

	[str appendFormat:@"\n%@}", selfIndent];
	return str;
}

@end

// feel free to implement handling NSData and NSDate here,
// it's not that straighforward as it is for basic data types, since
// - as far as I know - there's no literal initializer syntax for NSDate and NSData objects.

@implementation NSData (Plist2ObjC)

- (NSString *)recursiveDump:(NSInteger)level {
	[NSException raise:NSInvalidArgumentException
	            format:@"Unimplemented - handling NSData is not yet supported"];
	return nil;
}

@end

@implementation NSDate (Plist2ObjC)

- (NSString *)recursiveDump:(NSInteger)level {
	[NSException raise:NSInvalidArgumentException
	            format:@"Unimplemented - handling NSDate is not yet supported"];
	return nil;
}

@end


void printUsage()
{
	printf("Usage: plist2objc <file.plist>\n\n");
}

int main(int argc, char *argv[])
{
	@autoreleasepool {
		if (argc == 2) {
			NSString *file = [NSString stringWithUTF8String:argv[1]];

			id <Plist2ObjC_Dumpable> obj = [NSDictionary dictionaryWithContentsOfFile:file];
			if (obj == nil) {
				// not a dictionary - should be an array
				obj = [NSArray arrayWithContentsOfFile:file];
				if (obj == nil) {
					// not an array either, must be an invaild file.
					printUsage();
					printf("Error: Invaild file supplied.\n");
					return EXIT_FAILURE;
				}

			}

			NSString *code = [obj recursiveDump:0];
			printf("%s\n", [code UTF8String]);

			return EXIT_SUCCESS;
		}

		printUsage();
		printf("Error: Invaild arguments supplied.\n");
		return EXIT_FAILURE;
	}
}
