/*
 * Plist2ObjC.m
 * Plist2ObjC
 *
 * Created by Arpad Goretity on 24/10/2012
 * Licensed under the 3-clause BSD License
 */

#import <stdio.h>
#import <Foundation/Foundation.h>

#define MAX_DEPTH 64 // maximal recursion and indentation depth

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

NSString *recursiveDump(id object, int level)
{
	// maximal indentation: 64 tabs, equals `MAX_DEPTH`
	static const char *indent = "\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t";
	
	if (level >= MAX_DEPTH) [NSException raise:NSInternalInconsistencyException format:@"Nested too deep"];
    
	const char *selfIndent = indent + MAX_DEPTH - level;
	const char *childIndent = indent + MAX_DEPTH - (level + 1);
    
	if ([object isKindOfClass:[NSString class]]) {
		return [NSString stringWithFormat:@"%s@\"%@\"", selfIndent, [object stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""]];
	} else if ([object isKindOfClass:[NSNumber class]]) {
		return [NSString stringWithFormat:@"%s@%@", selfIndent, object];
	} else if ([object isKindOfClass:[NSArray class]]) {
		NSMutableString *str = [NSMutableString stringWithString:@"@[\n"];
		NSInteger size = [object count];
		NSInteger i;
		for (i = 0; i < size; i++) {
			if (i > 0) [str appendString:@",\n"];
			[str appendFormat:@"%s%@", childIndent, removeIndentation(recursiveDump([object objectAtIndex:i], level + 1))];
		}
		[str appendFormat:@"\n%s]", selfIndent];
		return str;
	} else if ([object isKindOfClass:[NSDictionary class]]) {
		NSMutableString *str = [NSMutableString stringWithString:@"@{\n"];
		NSString *key;
		NSInteger size = [object count];
		NSArray *keys = [object allKeys];
		NSInteger i;
		for (i = 0; i < size; i++) {
			if (i > 0) [str appendString:@",\n"];
			key = [keys objectAtIndex:i];
			[str appendFormat:@"%s%@: %@", childIndent, removeIndentation(recursiveDump(key, level + 1)), removeIndentation(recursiveDump([object objectForKey:key], level + 1))];
		}
		[str appendFormat:@"\n%s}", selfIndent];
		return str;
	} else {
		// feel free to implement handling NSData and NSDate here,
		// it's not that straighforward as it is for basic data types, since
		// - as far as I know - there's no literal initializer syntax for NSDate and NSData objects.
		[NSException raise:NSInvalidArgumentException format:@"Unimplemented - handling NSData and NSDate is not yet supported"];
		return nil;
	}
}

void printUsage()
{
    printf("Usage: plist2objc <file.plist>\n\n");
}

int main(int argc, char *argv[])
{
    if (argc == 2)
    {
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        
        NSString *file = [NSString stringWithUTF8String:argv[1]];
        
        id obj = [NSDictionary dictionaryWithContentsOfFile:file];
        if (obj == nil) {
            // not a dictionary - should be an array
            obj = [NSArray arrayWithContentsOfFile:file];
            if (obj == nil) {
                // not an array either, must be an invaild file.
                printUsage();
                printf("Error: Invaild file supplied.\n");
                [pool release];
                return EXIT_FAILURE;
            }
            
        }
        NSString *code = recursiveDump(obj, 0);
        printf("%s\n", [code UTF8String]);
        
        [pool release];
        return EXIT_SUCCESS;
    }
    
    printUsage();
    
    printf("Error: Invaild arguments supplied.\n");
    
    return EXIT_FAILURE;
}

