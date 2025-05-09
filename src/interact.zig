const std = @import("std");
const huff = @import("huffman.zig");
const storage = @import("storage.zig");

pub fn initialze(reader: anytype) !void {
    var bufout = std.io.bufferedWriter(std.io.getStdOut().writer());
    var out_writer = bufout.writer();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const N = try scanInt(u8, reader);
    var raw_inputs = try allocator.alloc(huff.RawWeightedItem, N);
    defer allocator.free(raw_inputs);

    var ch: u8 = undefined;
    var weight: u16 = undefined;

    for (0..N) |i| {
        ch = try scanNextChar(reader);
        weight = try scanInt(u16, reader);
        raw_inputs[i] = huff.RawWeightedItem{
            .character = ch,
            .weight = weight,
        };
    }

    const huffmanTree = try huff.buildHuffmanTree(allocator, N, raw_inputs);
    defer huffmanTree.deinit();

    try storage.saveHuffmanTree(huffmanTree, "hfmTree");

    try out_writer.print("Huffman tree has been saved to hfmTree\n", .{});
    try bufout.flush();
}

pub fn encoding() !void {
    // var bufout = std.io.bufferedWriter(std.io.getStdOut().writer());
    // var out_writer = bufout.writer();
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const huffmanTree = try storage.loadHuffmanTree(allocator, "hfmTree");
    defer huffmanTree.deinit();

    const toBeTran = try storage.readFromFile(allocator, "ToBeTran");
    defer allocator.free(toBeTran);

    // try out_writer.print("Input file: {any}\n", .{huffmanTree});
    // try bufout.flush();

    const home = std.fs.cwd();
    var output_file = try home.createFile("CodeFile", .{});
    defer output_file.close();
}

pub fn scanInt(comptime T: type, reader: anytype) !T {
    var buf: [@bitSizeOf(T) + 2]u8 = undefined; // TODO: 这里应该有个精妙的公式, 以支持更多进制
    const length = try scanNextToken(reader, &buf);
    return std.fmt.parseInt(T, buf[0..length], 10);
}

pub fn scanNextChar(reader: anytype) !u8 {
    var c: u8 = ' ';
    while (std.ascii.isWhitespace(c)) {
        c = try reader.readByte();
    }
    return c;
}

// fn scanNextString(allocator: std.mem.Allocator, reader: anytype) ![]const u8 {
//     var buf: [256]u8 = undefined; // TODO: 这里应该有个精妙的公式, too
//     const length = try scanNextToken(reader, &buf);
//     return buf[0..length];
// }

// 以空白字符为界限获取下一个输入, 返回获取的有效位数，含 '\0'
pub fn scanNextToken(reader: anytype, buffer: []u8) !u16 {
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

    return i;
}
