{
  pkgs ? import <nixpkg> { },
  beholder,
  beholderDatabase,
}:
let
  beholderCommand =
    subcmd:
    "${beholder}/bin/beholder -t sec -vv snapshot --database-url ${beholderDatabase} binance ${subcmd}";
  beholderCSV = market: ./${market}_queries.csv;
  beholderKline =
    {
      market,
      interval,
      limit,
    }:
    let
      csv = beholderCSV market;
    in
    beholderCommand "kline --market ${market} --csv ${csv} --interval ${interval} --limit ${builtins.toString limit}";
  beholderOpenInterestSummary =
    {
      interval,
      limit,
    }:
    let
      csv = beholderCSV "usdm";
    in
    beholderCommand "open-interest-summary --csv ${csv} --interval ${interval} --limit ${builtins.toString limit}";
in
{
  mkBeholderScript =
    {
      name,
      interval,
      limit,
    }:
    pkgs.writeShellScriptBin name ''
      ${beholderOpenInterestSummary {
        interval = interval;
        limit = limit;
      }}
      ${beholderKline {
        market = "spot";
        interval = interval;
        limit = limit;
      }}
      ${beholderKline {
        market = "usdm";
        interval = interval;
        limit = limit;
      }}
    '';
  beholder-all-script = pkgs.writeShellScriptBin "beholder-all" ''
    ${beholderOpenInterestSummary {
      interval = "1d";
      limit = 500;
    }}
    ${beholderOpenInterestSummary {
      interval = "1h";
      limit = 500;
    }}
    ${beholderOpenInterestSummary {
      interval = "15m";
      limit = 500;
    }}
    ${beholderKline {
      market = "spot";
      interval = "1d";
      limit = 1000;
    }}
    ${beholderKline {
      market = "spot";
      interval = "1h";
      limit = 1000;
    }}
    ${beholderKline {
      market = "spot";
      interval = "15m";
      limit = 1000;
    }}
    ${beholderKline {
      market = "usdm";
      interval = "1d";
      limit = 1000;
    }}
    ${beholderKline {
      market = "usdm";
      interval = "1h";
      limit = 1000;
    }}
    ${beholderKline {
      market = "usdm";
      interval = "15m";
      limit = 1000;
    }}
  '';
}
