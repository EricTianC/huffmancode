const std = @import("std");

pub fn Stack(comptime T: type) type {
    return struct {
        data: []T,
        top: isize,
        allocator: std.mem.Allocator,

        pub fn init(allocator: std.mem.Allocator) !Stack(T) {
            const stack = Stack(T){
                .data = try allocator.alloc(T, 8),
                .top = -1,
                .allocator = allocator,
            };
            return stack;
        }

        pub fn deinit(self: *Stack(T)) void {
            self.allocator.free(self.data);
        }

        pub fn clear(self: *Stack(T)) void {
            self.top = -1;
        }

        pub fn is_empty(self: *Stack(T)) bool {
            return self.top == -1;
        }

        pub fn length(self: *Stack(T)) usize {
            // std.debug.print(".top {}\n", .{self.top});
            return @intCast(self.top + 1);
        }

        fn _increment(self: *Stack(T)) !void {
            var new_buffer = try self.allocator.alloc(T, self.data.len * 2);
            for (self.data, 0..) |item, i| {
                new_buffer[i] = item;
            }
            self.allocator.free(self.data);
            self.data = new_buffer;
        }

        pub fn push(self: *Stack(T), value: T) !void {
            if (self.top == self.data.len - 1) {
                try self._increment();
            }
            self.top += 1;
            self.data[@intCast(self.top)] = value;
        }

        pub fn pop(self: *Stack(T)) !T {
            if (self.top == -1) {
                return error.StackUnderflow;
            }
            // std.debug.print(".top {}\n", .{self.top});
            self.top = self.top - 1;
            // std.debug.print(".top {}\n", .{self.top});
            return self.data[@intCast(self.top + 1)]; // TODO: Atomic, 线程安全
        }

        pub fn peek(self: *Stack(T)) !T {
            if (self.top == -1) {
                return error.StackUnderflow;
            }
            return self.data[@intCast(self.top)];
        }
    };
}

test "Stack" {
    const testing = std.testing;

    const allocator = testing.allocator;
    var stack = try Stack(u8).init(allocator);
    defer stack.deinit();

    try stack.push(1);
    try stack.push(2);
    try stack.push(3);

    const top = try stack.pop();
    try testing.expectEqual(3, top);

    const peek = try stack.peek();
    try testing.expectEqual(2, peek);

    const length = stack.length();
    try testing.expectEqual(2, length);

    stack.clear();
    try testing.expectEqual(0, stack.length());
}
