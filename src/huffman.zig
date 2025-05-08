//! 使用静态三叉链表实现哈夫曼树
const std = @import("std");

/// 原始输入得到的权值带权值结点
pub const RawWeightedItem = struct {
    character: u8, // 应该够存完字母表，只应对实验用 // TODO: 整体修改应对其它情形
    weight: u16,
};

pub const HuffmanNode = struct {
    weight: u64,
    parent: u16,
    lchild: u16,
    rchild: u16,
};

/// 静态三叉链表实现哈夫曼树
/// 0 号单元空闲不用
/// 1..n 号单元存放权值结点
/// n+1..2*n 号单元存放非权值结点
pub const HuffmanTree = struct {
    leaf_num: u8,
    hufftable: []HuffmanNode,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, leaf_num: u8) !HuffmanTree {
        return .{ .allocator = allocator, .leaf_num = leaf_num, .hufftable = try allocator.alloc(HuffmanNode, 2 * leaf_num) };
    }

    pub fn deinit(self: HuffmanTree) void {
        self.allocator.free(self.hufftable);
    }
};

pub fn buildHuffmanTree(allocator: std.mem.Allocator, n: u8, witems: []const RawWeightedItem) !HuffmanTree {
    std.debug.assert(n > 0);

    var huffTree = try HuffmanTree.init(allocator, n);
    var hufftable = huffTree.hufftable;

    for (1..2 * n) |i| {
        hufftable[i].weight = if (i <= n) witems[i - 1].weight else 0;
        hufftable[i].parent = 0;
        hufftable[i].lchild = 0;
        hufftable[i].rchild = 0;
    }

    // 反复选择权值最小的两个结点
    for (n + 1..2 * n) |i| {
        var min_weight1: u64 = undefined;
        var min_index1: u16 = 0;
        var min_weight2: u64 = undefined;
        var min_index2: u16 = 0;

        for (1..i) |k| {
            if (huffTree.hufftable[k].parent != 0) {
                continue;
            }
            if (min_index1 == 0 or huffTree.hufftable[k].weight < min_weight1) {
                min_weight2 = min_weight1;
                min_index2 = min_index1;
                min_weight1 = huffTree.hufftable[k].weight;
                min_index1 = @intCast(k);
            } else if (min_index2 == 0 or huffTree.hufftable[k].weight < min_weight2) {
                min_weight2 = huffTree.hufftable[k].weight;
                min_index2 = @intCast(k);
            }
        }
        huffTree.hufftable[i].weight = min_weight1 + min_weight2;
        huffTree.hufftable[i].lchild = min_index1;
        huffTree.hufftable[i].rchild = min_index2;
        huffTree.hufftable[min_index1].parent = @intCast(i);
        huffTree.hufftable[min_index2].parent = @intCast(i);
    }
    return huffTree;
}

const testing = std.testing;
test "test buildHuffmanTree" {
    // const allocator = std.heap.page_allocator;
    const n = 5;
    const witems: [n]RawWeightedItem = [_]RawWeightedItem{
        .{ .character = 'a', .weight = 11 },
        .{ .character = 'b', .weight = 9 },
        .{ .character = 'c', .weight = 3 },
        .{ .character = 'd', .weight = 13 },
        .{ .character = 'e', .weight = 16 },
    };

    const huffTree = buildHuffmanTree(testing.allocator, n, witems[0..]) catch unreachable;
    defer huffTree.deinit();
    try testing.expectEqual(huffTree.hufftable[1].weight, 11);
    try testing.expectEqual(huffTree.hufftable[2].weight, 9);
    try testing.expectEqual(huffTree.hufftable[3].weight, 3);
    try testing.expectEqual(huffTree.hufftable[4].weight, 13);
    try testing.expectEqual(huffTree.hufftable[5].weight, 16);
    try testing.expectEqual(huffTree.hufftable[6], HuffmanNode{ .weight = 12, .parent = 7, .lchild = 3, .rchild = 2 });
    // defer allocator.free(huffTree);
}
