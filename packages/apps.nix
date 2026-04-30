{ pkgs, packages }:

let
  app = package: {
    type = "app";
    program = pkgs.lib.getExe package;
  };
in
{
  camoufox = app packages.camoufox;
  camoufox-vulpineos = app packages.camoufox-vulpineos;
  camoufox-python = app packages.python-camoufox;
  camofox-cli = app packages.camofox-cli;
  camofox-browser = app packages.camofox-browser;
  jo-camofox-browser = app packages.jo-camofox-browser;
  camofox-mcp = app packages.camofox-mcp;
  camoufox-js = app packages.camoufox-js;
  camoufox-mcp-server = app packages.camoufox-mcp-server;
  camoufox-browser-cli = app packages.camoufox-browser-cli;
  foxbridge = app packages.foxbridge;
  vulpineos = app packages.vulpineos;
  default = app packages.python-camoufox;
}
