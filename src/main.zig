const std = @import("std");
/// This imports the separate module containing `root.zig`. Take a look in `build.zig` for details.
const huff = @import("huffman.zig");
const storage = @import("storage.zig");
// const scan = @import("scanner.zig"); 暂时弃用这种方法

pub fn main() !void {
    // var gpa = std.heap.DebugAllocator(.{}){};
    // const allocator = gpa.allocator();

    // const n = 5;
    // const witems: [n]huff.RawWeightedItem = [_]huff.RawWeightedItem{
    //     .{ .character = 'a', .weight = 11 },
    //     .{ .character = 'b', .weight = 9 },
    //     .{ .character = 'c', .weight = 3 },
    //     .{ .character = 'd', .weight = 13 },
    //     .{ .character = 'e', .weight = 16 },
    // };

    // const huffTree = huff.buildHuffmanTree(allocator, n, witems[0..]) catch unreachable;
    // defer huffTree.deinit();

    // // std.debug.print("{any}", .{huffTree});

    // const filepath = "test_hfmTree";
    // try storage.saveHuffmanTree(huffTree, filepath);

    // std.debug.print("Huffman tree saved to {s}\n", .{filepath});

    // var scanner = scan.Scanner.init(std.io.getStdIn());
    const stdin = std.io.getStdIn();
    var bufin = std.io.bufferedReader(stdin.reader());

    const stdout = std.io.getStdOut();
    var bufout = std.io.bufferedWriter(stdout.writer());

    var out_writer = bufout.writer();

    var buf: [100]u8 = .{0} ** 100;
    try scanNextToken(bufin.reader(), &buf);

    try out_writer.print("I scanned {s}", .{buf});

    try bufout.flush();
}

// 以空白字符为界限获取下一个输入
fn scanNextToken(reader: anytype, buffer: []u8) !void {
    var c: u8 = ' ';

    // 吸收空白字符
    while (std.ascii.isWhitespace(c)) {
        c = try reader.readByte();
    }

    var i: u16 = 0;
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
