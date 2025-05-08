const std = @import("std");
/// This imports the separate module containing `root.zig`. Take a look in `build.zig` for details.
const huff = @import("huffman.zig");

pub fn main() !void {
    var gpa = std.heap.DebugAllocator(.{}){};
    const allocator = gpa.allocator();

    const n = 5;
    const witems: [n]huff.RawWeightedItem = [_]huff.RawWeightedItem{
        .{ .character = 'a', .weight = 11 },
        .{ .character = 'b', .weight = 9 },
        .{ .character = 'c', .weight = 3 },
        .{ .character = 'd', .weight = 13 },
        .{ .character = 'e', .weight = 16 },
    };

    const huffTree = huff.buildHuffmanTree(allocator, n, witems[0..]) catch unreachable;
    defer huffTree.deinit();

    std.debug.print("{any}", .{huffTree});
}
