const std = @import("std");
const storage = @import("src/storage.zig");
const interact = @import("src/interact.zig");

pub fn main() !void {
    const file = try std.fs.cwd().openFile("ToBeTran", .{});
    defer file.close();

    var buffer: [1024]u8 = .{0x00} ** 1024;
    _ = file.readAll(&buffer) catch |err| {
        std.debug.print("Error reading file: {}\n", .{err});
        return err;
    };

    const another_file = try std.fs.cwd().openFile("testdata", .{});
    defer another_file.close();

    var another_buffer: [1024]u8 = .{0x00} ** 1024;
    _ = another_file.readAll(&another_buffer) catch |err| {
        std.debug.print("Error writing to file: {}\n", .{err});
        return err;
    };

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const file_read_from_model = try storage.readFromFile(allocator, "ToBeTran");
    defer allocator.free(file_read_from_model);

    // Print the contents of the buffer

    std.debug.print("{s}", .{buffer});
    std.debug.print("{s}", .{another_buffer});
    std.debug.print("{s}", .{file_read_from_model});

    try interact.encoding();
}
