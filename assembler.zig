const std = @import("std");

var ac: u8 = 0;
var pc: u8 = 0;

const Area = enum { dados, configuracao, programa };
const Tipo_Token = enum { endereco, dado, operacao, variavel };

const Token = struct {
    area: Area,
    tipo: Tipo_Token,
    dado: []u8,
};

pub fn tratarDados(line: []const u8) void {
    std.debug.print("Linha dentro da tratarDados: {s}\n", .{line});
}

pub fn tratarConfiguracao(line: []const u8) void {
    std.debug.print("Linha dentro do tratarConfiguracao: {s}\n", .{line});
}

pub fn tratarPrograma(line: []const u8) void {
    std.debug.print("Linha dentro do tratarPrograma: {s}\n", .{line});
}

pub fn main() !void {
    std.debug.print("Hello World!!\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var mapa = std.AutoHashMap(Area, *const fn ([]const u8) void).init(gpa.allocator());
    defer mapa.deinit();

    try mapa.put(Area.configuracao, tratarConfiguracao);
    try mapa.put(Area.dados, tratarDados);
    try mapa.put(Area.programa, tratarPrograma);

    const arquivo = try std.fs.cwd().openFile("arquivo_base.asm", .{});
    defer arquivo.close();

    var buffer: [1024]u8 = undefined;

    var file_reader = arquivo.reader(&buffer);

    var areaAtual: Area = Area.configuracao;

    //  const reader: *std.Io.Reader = &file_reader.interface;
    //std.debug.print("{s}\n", .{reader.buffered()});

    while (true) {
        const line = file_reader.interface.takeDelimiterInclusive('\n') catch |err| switch (err) {
            error.EndOfStream => break,
            error.ReadFailed => |e| return file_reader.err orelse e,
            else => |e| return e,
        };

        const linhaTratada = std.mem.trim(u8, line, &std.ascii.whitespace);

        if (linhaTratada.len == 0) {
            continue;
        }

        if (std.mem.startsWith(u8, linhaTratada, ";")) {
            continue;
        }

        if (std.mem.startsWith(u8, linhaTratada, "#DADOS")) {
            areaAtual = Area.dados;
            continue;
        }

        if (std.mem.startsWith(u8, linhaTratada, "#CONFIGURACAO")) {
            areaAtual = Area.configuracao;
            continue;
        }

        if (std.mem.startsWith(u8, linhaTratada, "#PROGRAMA")) {
            areaAtual = Area.programa;
            continue;
        }

        if (mapa.get(areaAtual)) |funcao| {
            funcao(linhaTratada);
        }
    }

    std.debug.print("Rodou ate o fim!\n", .{});
}
