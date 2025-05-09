const std = @import("std");
const huff = @import("huffman.zig");
const storage = @import("storage.zig");

// 因作业要求，暂限定必须按空格加字母表格式给
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

    //处理开头的空格
    ch = ' ';
    weight = try scanInt(u16, reader);
    raw_inputs[0] = huff.RawWeightedItem{ .character = ch, .weight = weight };

    for (1..N) |i| {
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

    var output_file = try std.fs.cwd().createFile("CodeFile", .{});
    defer output_file.close();

    var i: u16 = 0;
    while (toBeTran[i] != 0x00) : (i += 1) {
        const huffcode: []u8 = try encodeSingleChar(allocator, toBeTran[i], huffmanTree);
        for (huffcode) |code| {
            if (code == 0x00) {
                break;
            } else {
                _ = try output_file.write(&[_]u8{code});
            }
        }
        defer allocator.free(huffcode);
    }
}

// 暂时只支持字母表顺序
fn encodeSingleChar(allocator: std.mem.Allocator, ch: u8, huffman: huff.HuffmanTree) ![]u8 {
    // std.debug.assert(huffman.leaf_num == 26);
    std.debug.print("encoding: {c}\n", .{ch});

    const table = huffman.hufftable;

    var code = try allocator.alloc(u8, huffman.leaf_num);

    code[0] = 0x00;
    var i: u16 = 1;
    var ht_index: u16 = undefined;
    if (ch == ' ') {
        ht_index = 1;
    } else {
        ht_index = @intCast(std.ascii.toLower(ch) - 0x60 + 1);
    }

    while (table[ht_index].parent != 0) : ({
        i += 1;
        ht_index = table[ht_index].parent;
    }) {
        code[i] = if (ht_index == table[table[ht_index].parent].lchild) '0' else '1';
    }
    std.mem.reverse(u8, code[0..i]);
    return code;
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
