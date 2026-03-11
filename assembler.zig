const std = @import("std");

var ac: u8 = 0;
var pc: u8 = 0;

const Area = enum { dados, configuracao, programa };

pub fn main() !void {
    std.debug.print("Hello World!!\n", .{});

    const arquivo = try std.fs.cwd().openFile("arquivo_base.asm", .{});
    defer arquivo.close();

    var buffer: [1024]u8 = undefined;

    var file_reader = arquivo.reader(&buffer);

    const reader: *std.Io.Reader = &file_reader.interface;

    try reader.fillMore();

    std.debug.print("{s}\n", .{reader.buffered()});

    std.debug.print("Rodou ate o fim!\n", .{});
}
