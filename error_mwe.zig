//! 速通 openFile Error

const std = @import("std");

pub fn read(filepath: []const u8) !void {
    var home = std.fs.cwd();
    defer home.close();

    var file = try home.openFile(filepath, .{});
    defer file.close();
}

pub fn main() !void {
    std.debug.print("在当前目录下创建 test 文件\n", .{});
    var file = try std.fs.cwd().createFile("test", .{});
    defer file.close();

    try read("test");
    // try read("test");

    std.debug.print("现在打开文件为上面这行取消注释，再试一试", .{});
}
