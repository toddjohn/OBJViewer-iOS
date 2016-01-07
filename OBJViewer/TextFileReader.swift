//
//  TextFileReader.swift
//  OBJViewer
//
//  Created by Todd Johnson on 1/4/16.
//  Copyright © 2016 Todd Johnson. All rights reserved.
//

import UIKit

class TextFileReader: NSObject {
    let blockSize = 2048
    let delimiter = "\n".dataUsingEncoding(NSUTF8StringEncoding)!

    private var fileHandle: NSFileHandle!
    private var buffer: NSMutableData!
    private var atEOF = false
    private(set) var fileSize: UInt64 = 0

    init?(path: String) {
        super.init()

        if let handle = NSFileHandle(forReadingAtPath: path) {
            self.fileHandle = handle
            self.fileSize = self.fileHandle.seekToEndOfFile()
            self.fileHandle.seekToFileOffset(0)
            self.buffer = NSMutableData(capacity: self.blockSize)
        } else {
            self.fileHandle = nil
            self.buffer = nil
            return nil
        }
    }

    deinit {
        self.close()
    }

    func currentFilePosition() -> UInt64 {
        precondition(self.fileHandle != nil, "No file opened for reading")

        return self.fileHandle.offsetInFile
    }

    func nextLine() -> String? {
        precondition(self.fileHandle != nil, "No file opened for reading")

        if atEOF {
            return nil
        }

        var range = self.buffer.rangeOfData(self.delimiter, options: [], range: NSMakeRange(0, self.buffer.length))
        while range.location == NSNotFound {
            let temp = self.fileHandle.readDataOfLength(self.blockSize)
            if temp.length == 0 {
                self.atEOF = true
                if buffer.length > 0 {
                    let line = NSString(data: self.buffer, encoding: NSUTF8StringEncoding)
                    self.buffer.length = 0

                    return line as String?
                }

                return nil
            }
            self.buffer.appendData(temp)
            range = self.buffer.rangeOfData(self.delimiter, options: [], range: NSMakeRange(0, self.buffer.length))
        }

        let line = NSString(data: self.buffer.subdataWithRange(NSMakeRange(0, range.location)), encoding: NSUTF8StringEncoding)
        self.buffer.replaceBytesInRange(NSMakeRange(0, range.location + range.length), withBytes: nil, length: 0)

        return line as String?
    }

    func close() {
        self.fileHandle?.closeFile()
        self.fileHandle = nil
    }
}
