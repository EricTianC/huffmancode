const std = @import("std");
/// This imports the separate module containing `root.zig`. Take a look in `build.zig` for details.
const huff = @import("huffman.zig");
const storage = @import("storage.zig");
const interact = @import("interact.zig");
// const scan = @import("scanner.zig"); 暂时弃用这种方法

const menu =
    \\初始化(I)
    \\编码(E)
    \\解码(D)
    \\打印代码文件(P)
    \\打印Huffman树(T)
    \\退出(Q)
    \\请输入选项 >>> 
;

pub fn main() !void {
    // 初始化一堆输入输出相关项
    const stdin = std.io.getStdIn();
    var bufin = std.io.bufferedReader(stdin.reader());
    const reader = bufin.reader();
    var bufout = std.io.bufferedWriter(std.io.getStdOut().writer());
    var out_writer = bufout.writer();

    // var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    // const allocator = gpa.allocator();

    try out_writer.print(menu, .{});
    try bufout.flush();

    var option: u8 = try interact.scanNextChar(reader);
    option = std.ascii.toLower(option);
    while (option != 'q') : ({
        try out_writer.print(menu, .{});
        try bufout.flush();

        option = try interact.scanNextChar(reader);
        option = std.ascii.toLower(option);
    }) {
        switch (option) { // option 已小写化
            'i' => {
                try interact.initialze(reader);
            },
            'e' => {
                try interact.encoding();
            },
            'd' => {
                try interact.decoding();
            },
            'p' => {
                try interact.printCodeFile();
            },
            't' => {
                try interact.treePrinting();
            },
            else => {},
        }
    }

    try bufout.flush();
}
