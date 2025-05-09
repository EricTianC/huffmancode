//! 哈夫曼树的文件存储逻辑

const huffman = @import("huffman.zig");
const HuffmanTree = huffman.HuffmanTree;
const HuffmanNode = huffman.HuffmanNode;
const RawWeightedItem = huffman.RawWeightedItem;

const std = @import("std");

const head = "huff.zig:";

pub fn saveHuffmanTree(huff: HuffmanTree, filepath: []const u8) !void {
    var home = std.fs.cwd();
    defer home.close();

    var file = try home.createFile(filepath, .{});
    defer file.close();

    try file.writeAll(head);
    try file.writeAll(std.mem.asBytes(&huff.leaf_num));

    try file.writeAll(huff.vocab);
    try file.writeAll(std.mem.sliceAsBytes(huff.hufftable));
}

// TODO: 改写为 bufferd，以减少 syscall
pub fn loadHuffmanTree(allocator: std.mem.Allocator, filepath: []const u8) !HuffmanTree {
    var home = std.fs.cwd();
    defer home.close();

    var file = try home.openFile(filepath, .{});
    defer file.close();

    try file.seekTo(head.len);

    var leaf_num_bytes: [1]u8 = undefined;
    _ = try file.read(&leaf_num_bytes);
    const leaf_num = leaf_num_bytes[0];

    const vocab: []u8 = try allocator.alloc(u8, leaf_num);
    defer allocator.free(vocab);
    _ = try file.readAll(vocab);

    var huffnode_buf: [@sizeOf(HuffmanNode)]u8 = undefined;
    const huff = try HuffmanTree.init(allocator, leaf_num);

    for (0..leaf_num) |i| {
        huff.vocab[i] = vocab[i];
    } // 让编译器自己优化为 memset

    for (0..2 * leaf_num) |i| {
        _ = try file.readAll(&huffnode_buf);
        const huffnode = std.mem.bytesToValue(HuffmanNode, &huffnode_buf);
        huff.hufftable[i] = huffnode;
    }
    return huff;
}

const testing = std.testing;
test "load huffman" {
    const huff = loadHuffmanTree(std.testing.allocator, "test_hfmTree") catch unreachable;
    defer huff.deinit();

    try testing.expectEqualDeep((&[_]u8{ 'a', 'b', 'c', 'd', 'e' }), huff.vocab);
    try testing.expectEqual(11, huff.hufftable[1].weight);
    try testing.expectEqual(9, huff.hufftable[2].weight);
    try testing.expectEqual(3, huff.hufftable[3].weight);
    try testing.expectEqual(13, huff.hufftable[4].weight);
    try testing.expectEqual(16, huff.hufftable[5].weight);
    try testing.expectEqual(HuffmanNode{ .weight = 12, .parent = 7, .lchild = 3, .rchild = 2 }, huff.hufftable[6]);
    try testing.expectEqual(HuffmanNode{ .weight = 52, .parent = 0, .lchild = 7, .rchild = 8 }, huff.hufftable[9]);
}
