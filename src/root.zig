//! 使用静态三叉链表实现哈夫曼树
const std = @import("std");

/// 原始输入得到的权值带权值结点
pub const RawWeightedItem = struct {
    character: u8, // 应该够存完字母表，只应对实验用 // TODO: 整体修改应对其它情形
    weight: u16,
};

pub const HuffmanNode = struct {
    weight: u64,
    parent: u8,
    lchild: u8,
    rchild: u8,
};

/// ~暂时不用这个~
pub const HuffmanTree = struct {
    leaf_num: u8,
    hufftable: []HuffmanNode,
    allocator: std.mem.Allocator,

    fn init(allocator: std.mem.Allocator, leaf_num: u8) !HuffmanTree {
        return .{ .allocator = allocator, .leaf_num = leaf_num, .hufftable = allocator.alloc(HuffmanNode, leaf_num) };
    }

    fn deinit(self: HuffmanTree) void {
        self.allocator.free(self.hufftable);
    }
};

pub fn buildHuffmanTree(n: u8, witems: [n]RawWeightedItem) [2 * n]HuffmanNode {
    std.debug.assert(n > 0);

    var huffTree = [_]HuffmanNode{0} ** (2 * n); // 分配 HT 数组空间，0 号单元空闲不用
    for (0..n) |i| {
        huffTree[i + 1].weight = witems[i + 1].weight;
    }

    // 反复选择权值最小的两个结点
    for (n + 1..2 * n) |i| {
        var min_weight1: u64 = undefined;
        var min_index1: u16 = -1;
        var min_weight2: u64 = undefined;
        var min_index2: u16 = -1;

        for (1..i) |k| {
            if (huffTree[k].parent != 0) {
                continue;
            }
            if (min_index1 == -1 or huffTree[k] < min_weight1) {
                min_weight2 = min_weight1;
                min_index2 = min_index1;
                min_weight1 = huffTree[k].weight;
                min_index1 = k;
            } else if (min_index2 == -1 or huffTree[k] < min_weight2) {
                min_weight2 = huffTree[k].weight;
                min_index2 = k;
            }
        }
        huffTree[i].weight = min_weight1 + min_weight2;
        huffTree[i].lchild = min_index1;
        huffTree[i].rchild = min_index2;
        huffTree[min_index1].parent = i;
        huffTree[min_index2].parent = i;
    }
    return huffTree;
}

const testing = std.testing;
test "test build tree" {
    // const allocator = std.heap.page_allocator;
    const n = 5;
    const witems: [n]RawWeightedItem = [_]RawWeightedItem{
        .{ .character = 'a', .weight = 5 },
        .{ .character = 'b', .weight = 9 },
        .{ .character = 'c', .weight = 12 },
        .{ .character = 'd', .weight = 13 },
        .{ .character = 'e', .weight = 16 },
    };

    const huffTree = buildHuffmanTree(n, witems);
    testing.expectEqual(huffTree[1].weight, 5);
    testing.expectEqual(huffTree[2].weight, 9);
    testing.expectEqual(huffTree[3].weight, 12);
    testing.expectEqual(huffTree[4].weight, 13);
    // defer allocator.free(huffTree);
}
