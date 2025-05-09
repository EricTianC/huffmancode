//! 封装读取输入逻辑（暂时禁用封装形式）

const std = @import("std");
const File = std.fs.File;

pub const Scanner = struct {
    istream: File,
    buffer: std.io.BufferedReader(4096, std.fs.File.Reader), // TODO: modify magic number
    // buffer: anyopaque, // TODO: modify magic number

    pub fn init(istream: File) Scanner {
        return .{
            .istream = istream,
            .buffer = std.io.bufferedReader(istream.reader()),
        };
    }

    // 以空白字符为界限获取下一个输入
    pub fn scanNextToken(self: Scanner, buffer: []u8) !void {
        var reader = self.buffer.reader();

        var c: u8 = ' ';

        // 吸收空白字符
        while (std.ascii.isWhitespace(c)) {
            c = try reader.readByte();
        }

        var i = 0;
        while (!std.ascii.isWhitespace(c)) : ({
            c = try reader.readByte();
            i += 1;
        }) {
            if (i == buffer.len) {
                return error.RunOutOfBuffer;
            }
            buffer[i] = c;
        }

        if (i == buffer.len) {
            return error.RunOutOfBuffer;
        }
        buffer[i] = 0x00; // 写入 '\0'
    }
};
