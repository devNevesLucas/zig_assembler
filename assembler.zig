const std = @import("std");

var ac: u8 = 0;
var pc: u8 = 0;

const Area = enum { dados, configuracao, programa };
const Tipo_Token = enum { endereco, dado, operacao, definicao_config, definicao_variavel, nome_variavel, valor };

const Mnemonico = enum { guarde_em, carregue_de, some_de, ou, e, negado, pule, pn, pz, pare_agora };

const Token = struct {
    area: Area,
    tipo: Tipo_Token,
    dado: []const u8,

    pub fn ImprimirToken(self: Token) void {
        std.debug.print("Token na area: {s}, tipo: {s}, dado: {s}\n", .{ @tagName(self.area), @tagName(self.tipo), self.dado });
    }
};

const Token_Galho = struct {
    tipo: Tipo_Token,
    dado: []const u8,
    seguinte: Token_Galho
};

const Token_Ramo = struct {
    area: Area,
    tipo: Tipo_Token,
    dado: []const u8,
    no_galho: Token_Galho
};

pub fn valorMnemonico(mnemonico: Mnemonico) i32 {
    return switch (mnemonico) {
        .nada => 0b0000,
        .guarde_em => 0b0001,
        .carregue_de => 0b0010,
        .some_de => 0b0011,
        .ou => 0b0100,
        .e => 0b0101,
        .negado => 0b0110,
        .pule => 0b1000,
        .pn => 0b1001,
        .pz => 0b1010,
        .pare_agora => 0b1111,
        else => 0b0000
    };
};

pub fn tratarDados(lista: *std.ArrayList(Token), alocator: std.mem.Allocator, line: []const u8) std.mem.Allocator.Error!void {
    var iterador = std.mem.tokenizeAny(u8, line, &std.ascii.whitespace);

    var index: usize = 0;

    while (iterador.next()) |palavra| {
        switch (index) {
            0 => {
                try lista.append(alocator, Token{ .area = Area.dados, .tipo = Tipo_Token.definicao_variavel, .dado = palavra });
            },
            1 => {
                try lista.append(alocator, Token{ .area = Area.dados, .tipo = Tipo_Token.nome_variavel, .dado = palavra });
            },
            2 => {
                try lista.append(alocator, Token{ .area = Area.dados, .tipo = Tipo_Token.endereco, .dado = palavra });
            },
            3 => {
                try lista.append(alocator, Token{ .area = Area.dados, .tipo = Tipo_Token.valor, .dado = palavra });
            },
            else => {},
        }

        index = index + 1;
    }
}

pub fn tratarConfiguracao(lista: *std.ArrayList(Token), alocator: std.mem.Allocator, line: []const u8) std.mem.Allocator.Error!void {
    var iterador = std.mem.tokenizeAny(u8, line, &std.ascii.whitespace);

    var index: usize = 0;

    while (iterador.next()) |palavra| {
        switch (index) {
            0 => {
                try lista.append(alocator, Token{ .area = Area.configuracao, .tipo = Tipo_Token.definicao_config, .dado = palavra });
            },
            1 => {
                try lista.append(alocator, Token{ .area = Area.configuracao, .tipo = Tipo_Token.valor, .dado = palavra });
            },
            else => {},
        }

        index = index + 1;
    }
}

pub fn tratarPrograma(lista: *std.ArrayList(Token), alocator: std.mem.Allocator, line: []const u8) std.mem.Allocator.Error!void {
    var iterador = std.mem.tokenizeAny(u8, line, &std.ascii.whitespace);

    var index: usize = 0;

    while (iterador.next()) |palavra| {
        switch (index) {
            0 => {
                try lista.append(alocator, Token{ .area = Area.programa, .tipo = Tipo_Token.operacao, .dado = palavra });
            },
            1...2 => {
                try lista.append(alocator, Token{ .area = Area.programa, .tipo = Tipo_Token.endereco, .dado = palavra });
            },
            else => {},
        }

        index = index + 1;
    }
}

pub fn main() !void {
    std.debug.print("Hello World!!\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var mapa = std.AutoHashMap(Area, *const fn (*std.ArrayList(Token), std.mem.Allocator, []const u8) std.mem.Allocator.Error!void).init(gpa.allocator());
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

    var listaDeTokens: std.ArrayList(Token) = .empty;
    defer listaDeTokens.deinit(gpa.allocator());

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
            try funcao(&listaDeTokens, gpa.allocator(), linhaTratada);
        }
    }

    for (listaDeTokens.items) |token| {
        token.ImprimirToken();
    }

    std.debug.print("Rodou ate o fim!\n", .{});
}
