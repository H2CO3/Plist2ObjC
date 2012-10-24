all: plist2objc

plist2objc: Plist2Objc.m
	clang -o $@ $< -Wall -lobjc -framework Foundation

install: plist2objc
	cp $< /usr/bin/

clean:
	rm plist2objc
