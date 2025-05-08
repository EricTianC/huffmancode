const std = @import("std");
/// This imports the separate module containing `root.zig`. Take a look in `build.zig` for details.
const huff = @import("huffmancode_lib");

pub fn main() !void {
    const n = 5;
    const witems: [n]huff.RawWeightedItem = [_]huff.RawWeightedItem{
        .{ .character = 'a', .weight = 5 },
        .{ .character = 'b', .weight = 9 },
        .{ .character = 'c', .weight = 12 },
        .{ .character = 'd', .weight = 13 },
        .{ .character = 'e', .weight = 16 },
    };

    const huffTree = huff.buildHuffmanTree(n, witems);
    std.debug.print("{any}", huffTree);
    std.debug.print("Hello, world!\n", .{});
}
