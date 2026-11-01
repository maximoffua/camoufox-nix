{
  lib,
  buildPythonPackage,
  fetchPypi,
  hatchling,
  uv-dynamic-versioning,
  anyio,
  httpx,
  httpx-sse,
  jsonschema,
  pydantic,
  pydantic-settings,
  pyjwt,
  python-multipart,
  sse-starlette,
  starlette,
  typing-extensions,
  typing-inspection,
  uvicorn,
}:

# Camoufox MCP tools require the SDK v1 API, not nixpkgs' incompatible v2.
buildPythonPackage rec {
  pname = "mcp";
  version = "1.30.0";
  pyproject = true;
  src = fetchPypi {
    inherit pname version;
    hash = "sha256-RFQUYl/OXClfqlBbsRus7OZhq29AKNV8k121eCC3o+Q=";
  };
  build-system = [
    hatchling
    uv-dynamic-versioning
  ];
  dependencies = [
    anyio
    httpx
    httpx-sse
    jsonschema
    pydantic
    pydantic-settings
    pyjwt
    python-multipart
    sse-starlette
    starlette
    typing-extensions
    typing-inspection
    uvicorn
  ]
  ++ pyjwt.optional-dependencies.crypto;
  pythonImportsCheck = [
    "mcp.server.fastmcp"
    "mcp.client.stdio"
  ];
  meta = {
    description = "Model Context Protocol SDK v1 for Camoufox tools";
    homepage = "https://github.com/modelcontextprotocol/python-sdk";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
  };
}
