const std = @import("std");
const huff = @import("huffman.zig");
const storage = @import("storage.zig");
const ds = @import("datastructure.zig");
const assert = std.debug.assert;

// 因作业要求，暂限定必须按空格加字母表格式给定输入
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

    var buffered_output = std.io.bitWriter(.big, output_file.writer());

    // var bitcount: u64 = 0; // 处理末尾补齐
    for (toBeTran) |ch| {
        const huffcode: []u8 = try encodeSingleChar(allocator, ch, huffmanTree);
        for (huffcode) |code| {
            if (code == 0x00) {
                break;
            } else {
                const bitcode: u1 = switch (code) {
                    '0' => 0,
                    '1' => 1,
                    else => unreachable,
                };
                // _ = try output_file.write(&[_]u8{code});
                _ = try buffered_output.writeBits(bitcode, 1);
                // bitcount += 1;
            }
        }
        defer allocator.free(huffcode);
    }
    try buffered_output.writeBits(@as(u1, 1), 1);
    try buffered_output.flushBits(); // 尾字节补充 10...0
}

fn getBitAt(num: u8, index: u3) u1 {
    return @intCast((num >> index) & 0x01);
}

pub fn decoding() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const huffmanTree = try storage.loadHuffmanTree(allocator, "hfmTree");
    defer huffmanTree.deinit();
    const table = huffmanTree.hufftable;

    const codeFile = try storage.readFromFile(allocator, "CodeFile");
    defer allocator.free(codeFile);
    var actual_bit_length: u64 = undefined;
    var padding: u3 = 0; // 末尾填充 0 的位数

    if (codeFile[codeFile.len - 1] == 0x00) {
        return error.FileBroken;
    }
    while (getBitAt(codeFile[codeFile.len - 1], padding) == 0b0) {
        padding += 1;
    }

    actual_bit_length = 8 * codeFile.len - padding - 1;
    std.debug.print("CodeFile's actual bit length is {}.\n", .{actual_bit_length});

    var output_file = try std.fs.cwd().createFile("TextFile", .{});
    defer output_file.close();
    var output = std.io.bufferedWriter(output_file.writer());

    var out_writer = output.writer();

    var wrapped_codeFile = std.io.fixedBufferStream(codeFile);
    var bit_file_reader = std.io.bitReader(.big, wrapped_codeFile.reader());
    var bt_index: u16 = 2 * huffmanTree.leaf_num - 1;

    for (0..actual_bit_length) |_| {
        var bitcode: u1 = undefined;
        bitcode = try bit_file_reader.readBitsNoEof(
            u1,
            1,
        );
        std.debug.print("bitcode: {}\n", .{bitcode});
        if (bitcode == 0b0) {
            bt_index = table[bt_index].lchild;
        } else {
            bt_index = table[bt_index].rchild;
        }
        // _ = try output_file.write(&[_]u8{code});
        if (bt_index <= huffmanTree.leaf_num) {
            if (bt_index == 1) {
                try out_writer.writeByte(' ');
            } else {
                try out_writer.writeByte(@intCast(bt_index - 1 + 0x60));
            }
            bt_index = 2 * huffmanTree.leaf_num - 1;
        }
    }

    try output.flush();
}

// 暂时只支持字母表顺序, 这里暂时就按字符传吧
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

pub fn printCodeFile() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const codeFile = try storage.readFromFile(allocator, "CodeFile");
    defer allocator.free(codeFile);

    var actual_bit_length: u64 = undefined;
    var padding: u3 = 0; // 末尾填充 0 的位数

    if (codeFile[codeFile.len - 1] == 0x00) {
        return error.FileBroken;
    }
    while (getBitAt(codeFile[codeFile.len - 1], padding) == 0b0) {
        padding += 1;
    }

    actual_bit_length = 8 * codeFile.len - padding - 1;
    std.debug.print("CodeFile's actual bit length is {}.\n", .{actual_bit_length});

    var output_file = try std.fs.cwd().createFile("CodePrint", .{});
    defer output_file.close();
    var output = std.io.bufferedWriter(output_file.writer());
    var out_writer = output.writer();

    var wrapped_codeFile = std.io.fixedBufferStream(codeFile);
    var bit_file_reader = std.io.bitReader(.big, wrapped_codeFile.reader());

    for (0..actual_bit_length) |i| {
        var bitcode: u1 = undefined;
        bitcode = try bit_file_reader.readBitsNoEof(
            u1,
            1,
        );
        std.debug.print("{}", .{bitcode});
        if (bitcode == 0b0) {
            try out_writer.writeByte('0');
        } else {
            try out_writer.writeByte('1');
        }

        if ((i + 1) % 50 == 0) {
            std.debug.print("\n", .{});
            try out_writer.writeByte('\n');
        }
    }

    std.debug.print("\n", .{});
    try output.flush();
}

pub fn treePrinting() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const huffmanTree = try storage.loadHuffmanTree(allocator, "hfmTree");
    defer huffmanTree.deinit();
    const table = huffmanTree.hufftable;

    // std.debug.print("hufftable:\n{any}\n", .{table});

    var stack = try ds.Stack(u16).init(allocator);
    defer stack.deinit();

    var bufout = std.io.bufferedWriter(std.io.getStdOut().writer());
    var out_writer = bufout.writer();

    try out_writer.print("先序: \n", .{});

    var index: u16 = 2 * huffmanTree.leaf_num - 1;

    while (index != 0 or !stack.is_empty()) {
        while (index != 0) {
            if (index == 1) {
                try out_writer.print("{d:2} ~ \tweight: {}\n", .{ index, table[index].weight });
            } else if (index <= huffmanTree.leaf_num) {
                try out_writer.print("{d:2} {c} \tweight: {}\n", .{
                    index,
                    huffmanTree.vocab[index - 1],
                    table[index].weight,
                });
            } else {
                try out_writer.print("{d:2}  \tweight: {}\n", .{
                    index,
                    table[index].weight,
                });
            }

            try stack.push(index);
            index = table[index].lchild;
        }

        if (!stack.is_empty()) {
            index = try stack.pop();
            index = table[index].rchild;
        }
    } // PreOrder

    try out_writer.print("中序: \n", .{});

    index = 2 * huffmanTree.leaf_num - 1;

    while (index != 0 or !stack.is_empty()) {
        while (index != 0) {
            try stack.push(index);
            index = table[index].lchild;
        }

        if (!stack.is_empty()) {
            index = try stack.pop();
            if (index == 1) {
                try out_writer.print("{d:2} ~ \tweight: {}\n", .{ index, table[index].weight });
            } else if (index <= huffmanTree.leaf_num) {
                try out_writer.print("{d:2} {c} \tweight: {}\n", .{
                    index,
                    huffmanTree.vocab[index - 1],
                    table[index].weight,
                });
            } else {
                try out_writer.print("{d:2}  \tweight: {}\n", .{
                    index,
                    table[index].weight,
                });
            }
            index = table[index].rchild;
        }
    } // InOrder

    try bufout.flush();
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
