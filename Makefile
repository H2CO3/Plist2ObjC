all: plist2objc

plist2objc: Plist2Objc.m
	clang -o $@ $< -Wall -g -lobjc -framework Foundation
