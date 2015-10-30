all: plist2objc

plist2objc: Plist2Objc.m
	clang -o $@ $< -Wall -lobjc -framework Foundation -fobjc-arc -O2 -std=c99

install: plist2objc
	cp $< /usr/bin/

clean:
	rm plist2objc
